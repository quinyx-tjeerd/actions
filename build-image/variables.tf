variable "repository_name" {
  description = "Name of the repo"
  type        = string
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN that manages the images"
}

variable "lifecycle_policy" {
  type        = string
  description = "the lifecycle policy to be applied to the ECR repo"
}

variable "cache_lifecycle_policy" {
  type        = string
  description = "the lifecycle policy to be applied to the ECR cache repo"
}

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
}

variable "cache" {
  description = "Whether to create a Cache repositry or not"
  type        = bool
  default     = true
}

variable "lambda" {
  description = "Whether this image is intended for use as lambda function"
  type        = bool
  default     = false
}

variable "org_pull" {
  description = "Whether everyone in the org should be allowed to pull this image"
  type        = bool
  default     = false
}