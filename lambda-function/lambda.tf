locals {
  service_name  = join("-", compact([var.service, var.name]))
  function_name = join("-", [local.service_name, var.environment])
  role_name     = coalesce(var.iam_role_name, join("_", ["lambda", local.service_name, var.environment]))

  env-vars = merge(
    var.environment_variables,
    {
      ENVIRONMENT = var.environment
    }
  )
  tags = merge(
    var.tags,
    {
      SERVICE = local.service_name
    }
  )
  image = try(var.image, null)
  vpc = {
    subnet_ids          = var.vpc ? data.aws_subnets.lambda["subnet"].ids : null
    security_group_ids  = var.vpc ? [data.aws_security_group.sg["secgroup"].id] : null
  }
}

data "aws_iam_role" "role" {
  name = local.role_name
}

data "aws_security_group" "sg" {
  for_each = local.vpc ? {secgroup = true } : {}
  filter {
    name   = "tag:Name"
    values = ["main:lambda:lambda"]
  }
}

data "aws_subnets" "lambda" {
  for_each = local.vpc ? {subnet = true } : {}
  filter {
    name   = "tag:Environment"
    values = ["lambda"]
  }

  filter {
    name   = "vpc-id"
    values = [module.ips-and-vpcs.vpc_ids[var.region]]
  }
}

module "ips-and-vpcs" {
  source = "../ips-and-vpcs"
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.4.0"

  function_name = local.function_name
  description   = try(var.description, null)

  create_package                          = false
  create_role                             = false
  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 7
  lambda_role                             = try(data.aws_iam_role.role.arn, null)

  package_type  = "Image"
  architectures = var.architectures

  image_uri             = local.image
  environment_variables = local.env-vars

  vpc_subnet_ids         = local.vpc.subnet_ids
  vpc_security_group_ids = local.vpc.security_group_ids
  tags                   = local.tags
}
