locals {
  service_name  = join("-", compact([var.service, var.component]))
  bucket_name = coalesce(var.custom_name, join("-", [local.service_name, var.environment, var.region]))
  encryption = var.kms_key_arn ? {
    kms_master_key_id = var.kms_key_arn
    sse_algorithm     = "aws:kms"
  } : {
    sse_algorithm     = "AES256"
  }
  tags = merge( var.tags, { Environment = var.environment, Role =	"S3 Bucket", Service = local.service_name, ManagedBy = "Terraform Automated Github Action" })

  allowed-users  = concat([], var.allowed_users)
  allowed-groups = concat(["devops-admins"], var.allowed_groups)
  allowed-roles  = concat([format("k8s_terraform_%s", var.environment)], var.allowed_roles)

  processed-allowed-entities = distinct(flatten(concat([
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
  )))

  restrict_access = length(concat(var.allowed_users, var.allowed_groups, var.allowed_roles)) > 0
  bucket_policy   = try(data.aws_iam_policy_document.bucket_policy["restricted"].json, "{}")
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
data "aws_iam_policy_document" "bucket_policy" {
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
  attach_policy  = local.restrict_access
  policy         = local.bucket_policy
  
  tags   = local.tags
}
