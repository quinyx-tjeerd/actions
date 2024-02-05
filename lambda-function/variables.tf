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
}

variable "description" {
  description = "description of the lambda"
  type        = string
  default     = null
}

variable "image" {
  description = "ecr image"
  type        = string
  default     = "488021763009.dkr.ecr.eu-central-1.amazonaws.com/sqs-to-kafka:test"
}

variable "environment_variables" {
  description = "Map containing environment variables"
  type        = map(string)
  default     = {}
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are ['x86_64'] and ['arm64']."
  type = list(string)
  default = ["arm64"]
}

variable "vpc" {
  description = "boolean whether this lambda should be in Quinyx VPC"
  type = bool
  default = false
}