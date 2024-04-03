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

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
}

variable "component" {
  description = "Component of service, like a sub division"
  type        = string
  default     = null
}

variable "description" {
  description = "description of the S3 bucket"
  type        = string
  default     = null
}

variable "custom_name" {
  description = "Bucket name override"
  type        = string
  default     = null
}

variable "versioning" {
  description = "object versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN to use KMS encryption, otherwise AES256 will be used"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules defined as list of objects [ {rule} ]"
  type        = list(any)
  default     = []
}

variable "allowed_users" {
  type        = list(string)
  description = "Limit access to specified users, will be combined with the groups and roles"
  default     = []
}
variable "allowed_groups" {
  type        = list(string)
  description = "Limit access to specified groups, will be combined with the users and roles"
  default     = []
}

variable "allowed_roles" {
  type        = list(string)
  description = "Limit access to specified roles, will be combined with the groups and users"
  default     = []
}

variable "cloudfront_origin_access_control" {
  type        = bool
  description = "Creates Cloudfront Origin Access Control, if true, which will be used by cloudfront to access this bucket"
  default     = false
}

variable "cloudfront_distribution_arns" {
  type        = list(string)
  description = "Cloudfront distribution ARNs that use this bucket as their origin, conflicts with and takes precendence over 'allows_(groups|roles|users)'"
  default     = []
}