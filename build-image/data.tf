locals {
  account-id = data.aws_caller_identity.current.account_id
}

# NOTE: this isn't really a public ECR repo; there's a condition
#       only allows reads from an org, so this is a false positive
#       in tfsec
# tfsec:ignore:aws-ecr-no-public-access
data "aws_iam_policy_document" "org_pull" {
  for_each = var.org_pull ? { policy = true } : {}
  statement {
    sid    = "All Accounts in the Org can pull"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${var.aws_account_id}"]
    }
  }
}

data "aws_iam_policy_document" "github_only_push" {
  statement {
    sid    = "Allow push only from github actions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${var.iam_role_arn}"]
    }
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${var.aws_account_id}"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  for_each = var.lambda ? { policy = true } : {}
  statement {
    sid    = "Allow usage as lambda function"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
