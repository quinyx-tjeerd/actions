locals {
  certs = {
    eu-central-1 = "arn:aws:acm:eu-central-1:488021763009:certificate/b81fc160-7626-42d4-b4e9-99eab089c57f"
    us-east-1 = "arn:aws:acm:us-east-1:488021763009:certificate/4f49ea16-3516-4015-8783-dee0ad3bb972"
  }

  processed_stages = [ 
    for stage in var.stages: 
      merge({variables = {}}, stage) 
    if try(stage.name, null) != null
  ]
  processed_resources = [ 
    for resource in var.resources: 
      merge(var.default_resource, resource) 
    if try(resource.path, null) != null
  ]
  description = try(var.description, "HTTP API Gateway for ${local.gateway_name}") 

  gateway_name = format("%s-%s", var.service, var.region)
  domain_name  = try(var.custom_domain_name, format("%s.lambda.quinyx.io", local.gateway_name))
  domain = regex("[^.]+.[^.]+$", local.domain_name)
  subdomain = replace(local.domain_name, regex(".[^.]+.[^.]+$", local.domain_name), "")
  custom_cert  = !endswith(local.domain_name, ".lambda.quinyx.io")
  domain_cert  = local.custom_cert ? try(module.acm["cert"].acm_certificate_arn, null) : try(local.certs[var.region], null)

  tags = merge( var.tags, { Environment = var.environment, Role =	"API Gateway", Service = var.service })

  stages = { for stage in local.processed_stages: stage.name => stage.variables}
  lambdas = { for resource in local.processed_resources: resource.path => resource if try(resource.lambda_arn, null) != null }

  integrations = { for resource in local.processed_resources:
    format("%s %s", upper(resource.method), resource.path) => resource
    if alltrue([try(resource.method, null) != null, try(resource.path, null) != null])
  }

  # add permission for this API Gateway to access the specified lambda's
  lambda_permissions = { for pair in setproduct(keys(local.stages), keys(local.lambdas)): 
    format("%s/%s", pair[1], pair[0]) => {
      stage = pair[0]
      method = try(local.lambdas[pair[1]].method, null)
      path = pair[1]
      function = replace(try(local.lambdas[pair[1]].lambda_arn, null), "$${stageVariables.Environment}", pair[0])}
    }
}

data "aws_route53_zone" "domain" {
  name = local.domain
}

#################
## Certificate
#################
module "acm" {
  for_each = local.custom_cert ? { cert = true } : {}
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.domain.zone_id

  validation_method = "DNS"

  wait_for_validation = true

  tags = merge({ Name = local.domain_name, Role = "Certificate" }, local.tags)
} 

#################
## API Gateway
#################
module "apigateways" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name          = local.gateway_name
  description   = local.description
  protocol_type = "HTTP"

  create_default_stage = false

  domain_name                 = local.domain_name
  domain_name_certificate_arn = local.domain_cert

  integrations = local.integrations
  tags = local.tags
}

resource "aws_apigatewayv2_stage" "stage" {
  for_each = local.stages
  api_id      = module.apigateways.apigatewayv2_api_id
  name        = each.key
  auto_deploy = true

  stage_variables = merge(each.value, { Environment = each.key })

  tags = merge(local.tags, { Environment = each.key })

  # Bug in terraform-aws-provider with perpetual diff
  lifecycle {
    ignore_changes = [deployment_id]
  }
}

resource "aws_apigatewayv2_api_mapping" "mapping" {
  for_each = local.stages
  
  api_id      = module.apigateways.apigatewayv2_api_id
  domain_name = module.apigateways.apigatewayv2_domain_name_id
  stage       = aws_apigatewayv2_stage.stage[each.key].id
  api_mapping_key = each.key
}

#################
## DNS Record
#################
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = data.aws_route53_zone.domain.zone_id

  records = [
    {
      name    = local.subdomain
      type    = "A"
      alias   = {
        name    = module.apigateways.apigatewayv2_domain_name_target_domain_name
        zone_id = module.apigateways.apigatewayv2_domain_name_hosted_zone_id
        evaluate_target_health = true
      }
    },
  ]
}

#################
## Lambda Execution Permission
#################
resource "aws_lambda_permission" "allow_api_gateway" {
  for_each      = local.lambda_permissions
  statement_id  = "apigateway-${local.gateway_name}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function
  principal     = "apigateway.amazonaws.com"
  source_arn    = format("%s/%s/%s%s", module.apigateways.apigatewayv2_api_arn, each.value.stage, each.value.method, each.value.path)
}