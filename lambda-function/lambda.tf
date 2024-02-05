locals {
  env-vars = merge(
    var.environment_variables,
    {
      ENVIRONMENT      = var.environment
    }
  )
  image = try(var.image, null)
  vpc = {
    enabled = var.vpc
    subnet_ids = var.vpc ? data.aws_subnets.lambda.ids : null
    security_group_ids = var.vpc ? [data.aws_security_group.sg.id] : null
  }
}

data "aws_iam_role" "role" {
  name = join("_", ["lambda", join("-", [var.service, var.name]), var.environment])
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

  function_name = join("-", [var.service, var.name, var.environment])
  description   = var.description

  create_package                          = false
  create_role                             = false
  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 7
  lambda_role                             = data.aws_iam_role.role.arn

  package_type  = "Image"
  architectures = var.architectures

  image_uri             = local.image
  environment_variables = local.env-vars

  vpc_subnet_ids         = local.vpc.subnet_ids
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  tags                   = var.tags
}
