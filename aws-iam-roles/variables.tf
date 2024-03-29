variable "tags" {
  description = "Tags to add to resources"
  default     = {}
  type        = map(string)
}

variable "service" {
  description = "Name of the service associated with these resources"
  type        = string
}

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
}

variable "roles_yaml" {
  description = "path to yaml file containing role definitions"
  type        = string
}