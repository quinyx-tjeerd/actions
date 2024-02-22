variable "region" {
  description = "Region to create resources in"
  type        = string
}

variable "tags" {
  description = "Tags to add to resources"
  default     = {}
  type        = map(string)
}

variable "environment" {
  description = "Environment of these resources"
  type        = string
}

variable "service" {
  description = "Name of the service associated with these resources"
  type        = string
}

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
}

variable "roles" {
  description = "yaml containing role definitions"
  type        = string
}