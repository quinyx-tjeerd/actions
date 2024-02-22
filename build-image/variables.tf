variable "repository_name" {
  description = "Name of the repo"
  type        = string
}

variable "iam_role" {
  type        = string
  description = "Self-hosted runner EC2 instance role"
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