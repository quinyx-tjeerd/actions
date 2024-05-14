locals {
  certs = {
    eu-central-1 = "arn:aws:acm:eu-central-1:488021763009:certificate/b81fc160-7626-42d4-b4e9-99eab089c57f"
    us-east-1 = "arn:aws:acm:us-east-1:488021763009:certificate/4f49ea16-3516-4015-8783-dee0ad3bb972"
  }
  zones = {
    "quinyx.io" = ""
    "quinyx.com" = ""
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
  custom_cert  = !endswith(local.domain_name, ".lambda.quinyx.io")
  domain_cert  = local.custom_cert ? try(module.acm["cert"].acm_certificate_arn, null) : try(local.certs[var.region], null)
  zone         = local.custom_cert ? try(local.zones[regex("[^.]+.[^.]+$", local.domain_name)], null) : null

  tags = merge( var.tags, { Environment = var.environment, Role =	"API Gateway", Service = var.service })

  stages = { for stage in local.processed_stages: stage.name => stage.variables}

  integrations = { for resource in local.processed_resources:
    format("%s %s", upper(resource.method), resource.path) => {
      lambda_arn             = try(resource.lambda_arn, null)
      timeout_milliseconds   = try(resource.timeout_milliseconds, 300)
    }
    if resource.method && resource.path
  }
}

module "acm" {
  for_each = local.custom_cert ? { cert = true } : {}
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = local.domain_name
  zone_id      = local.zone

  validation_method = "DNS"

  wait_for_validation = true

  tags = merge(local.tags, { Name = local.domain_name })
} 

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

  stage_variables = merge(each.value, { ENVIRONMENT = each.key })

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