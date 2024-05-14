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

variable "description" {
  description = "description of the api gateway"
  type        = string
  default     = null
}

variable "stages" {
  description = "List of stages to create"
  type = list(any)
  default = [{ name = "test" },{ name = "staging" },{ name = "rc" },{ name = "prod" }]
}

variable "resources" {
  description = "List of resources, must contain path"
  type = list(any)
}

variable "default_resource" {
  description = "Default object which the specified resources are applied upon"
  type = map(any)
  default = { timeout_milliseconds = 300 }
}

variable "custom_domain_name" {
  description = "In case you don't want the default 'service'-'region'.lambda.quinyx.io"
  type        = string
  default     = null
}
