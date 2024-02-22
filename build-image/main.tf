data "aws_caller_identity" "current" {}

locals {
  repos = merge({
    var.repository_name = {
      mutability = "IMMUTABLE"
      policy = templatefile(var.lifecycle_policy, {})
    } 
  },
  var.cache ? {
    format("%s/cache", var.repository_name) = {
      mutability = "IMMUTABLE"
      policy = templatefile(var.cache_lifecycle_policy, {})
    } 
  } : {}
  )
}

# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "repository" {
  for_each = local.repos
  name                 = each.key
  image_tag_mutability = each.value.mutability
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = local.repos
  repository = aws_ecr_repository.repository[each.key].name
  policy     = each.value.policy
}
