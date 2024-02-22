variable "region" {
  description = "Region to create resources in"
  type        = string
}

variable "tags" {
  description = "Tags to add to resources"
  default     = {}
  type        = map(any)
}

variable "environment" {
  description = "Environment of these resources"
  type        = string
}

variable "service" {
  description = "Name of the service associated with these resources"
  type        = string
}

variable "name" {
  description = "sub name, after service"
  type        = string
  default     = ""
}

variable "description" {
  description = "description of the lambda"
  type        = string
  default     = null
}

variable "image" {
  description = "ecr image"
  type        = string
}

variable "environment_variables" {
  description = "Map containing environment variables"
  type        = map(string)
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are ['x86_64'] and ['arm64']."
  type        = list(string)
}

variable "vpc" {
  description = "boolean whether this lambda should be in Quinyx VPC"
  type        = bool
}

variable "iam_role_name" {
  description = "IAM Role name to use instead of automatically determined based on service and env, default 'lambda_service-name_env'"
  type        = string
  default     = null
}