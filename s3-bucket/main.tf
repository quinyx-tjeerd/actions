locals {
  service_name  = join("-", compact([var.service, var.component]))
  bucket_name = coalesce(var.custom_name, join("-", [local.service_name, var.environment, var.region]))
  encryption = var.kms_key_arn != null ? {
    kms_master_key_id = var.kms_key_arn
    sse_algorithm     = "aws:kms"
  } : {
    sse_algorithm     = "AES256"
  }
  tags = merge( var.tags, { Environment = var.environment, Role =	"S3 Bucket", Service = local.service_name, ManagedBy = "Terraform Automated Github Action" })

  restrict_access = length(concat(var.allowed_users, var.allowed_groups, var.allowed_roles)) > 0
  restrict_cloudfront = length(var.cloudfront_distribution_arns) > 0
  allowed-users  = local.restrict_access ? concat([], var.allowed_users) : []
  allowed-groups = local.restrict_access ? concat(["devops-admins"], var.allowed_groups) : []
  allowed-roles  = local.restrict_access ? concat(["github-actions_s3-bucket"], var.allowed_roles) : []
  processed-allowed-entities = local.restrict_access ? distinct(flatten(concat([
      var.aws_account_id
    ], [
      for role in local.allowed-roles : format("%s:*", data.aws_iam_role.role[role].unique_id)
    ], [
      for user in local.allowed-users : data.aws_iam_user.user[user].id
    ], [
      for group in local.allowed-groups : [
        for user, user-info in data.aws_iam_group.group[group].users : user-info.user_id
      ]
    ]
  ))) : []
  attach_policy = local.restrict_cloudfront || local.restrict_access
  bucket_policy = local.restrict_cloudfront ? data.aws_iam_policy_document.cloudfront_policy["access"].json : local.restrict_access ? data.aws_iam_policy_document.restricted_policy["access"].json : null
}

#################
## Data Gathering
#################
data "aws_iam_user" "user" {
  for_each  = toset(local.allowed-users)
  user_name = each.key
}

data "aws_iam_group" "group" {
  for_each   = toset(local.allowed-groups)
  group_name = each.key
}

data "aws_iam_role" "role" {
  for_each = toset(local.allowed-roles)
  name     = each.key
}

#################
## Constructing Policy
#################
data "aws_iam_policy_document" "cloudfront_policy" {
  for_each = local.restrict_cloudfront ? { access = true } :{}
  statement {
    sid = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = var.cloudfront_distribution_arns
    }
  }
}

data "aws_iam_policy_document" "restricted_policy" {
  for_each = local.restrict_access ? { access = true } :{}
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values = local.processed-allowed-entities
    }
  }
}

#################
## Implement Module
#################
module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"
  
  create_bucket = true

  bucket = local.bucket_name

  //versioning
  versioning = {
    enabled = var.versioning
  }

  // encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = local.encryption
    }
  }

  lifecycle_rule = var.lifecycle_rules
  attach_policy  = local.attach_policy
  policy         = local.bucket_policy
  
  tags   = local.tags
}

resource "aws_cloudfront_origin_access_control" "oac" {
  for_each = var.cloudfront_origin_access_control ? { access = true } : {}
  name                              = join("_", ["cloudfront", local.bucket_name, "oac"])
  description                       = "CloudFront access to S3: ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}