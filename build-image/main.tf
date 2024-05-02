data "aws_caller_identity" "current" {}

locals {
  repos = merge({
    format("%s", var.repository_name) = {
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
  for_each             = local.repos
  name                 = each.key
  image_tag_mutability = each.value.mutability
  encryption_configuration {
    encryption_type = "KMS"
  }
  tags = var.tags
}

data "aws_iam_policy_document" "ecr_repo_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.github_only_push.json,
    var.lambda ? data.aws_iam_policy_document.lambda["policy"].json : "",
    var.org_pull ? data.aws_iam_policy_document.org_pull["policy"].json : ""
  ]
}

resource "aws_ecr_repository_policy" "repository" {
  repository = aws_ecr_repository.repository[format("%s", var.repository_name)].name
  policy     = data.aws_iam_policy_document.ecr_repo_policy.json
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each   = local.repos
  repository = aws_ecr_repository.repository[each.key].name
  policy     = each.value.policy
}
