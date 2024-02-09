data "aws_caller_identity" "current" {}

# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "repository" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "repository" {
  repository = aws_ecr_repository.repository.name
  policy     = templatefile(var.lifecycle_policy, {})
}

resource "aws_ecr_repository" "cache" {
  name                 = format("%s/cache", var.repository_name)
  image_tag_mutability = "IMMUTABLE"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "cache" {
  repository = aws_ecr_repository.cache.name
  policy     = templatefile(var.lifecycle_policy, {})
}