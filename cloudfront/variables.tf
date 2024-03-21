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

variable "component" {
  description = "Name of the service associated with these resources"
  type        = string
  default     = null
}

variable "description" {
  description = "description of the cloudfront distribution"
  type        = string
  default     = null
}

variable "bucket_id" {
  description = "Bucket ID"
  type        = string
}

variable "custom_error_responses" {
  description = "Custom error responses"
  type        = map(any)
  default     = {}
}

variable "domain" {
  type    = string
  default = "quinyx.com"
}

variable "subdomain" {
  type    = string
  default = null
}

variable "domain_aliases" {
  description = "List of CNAMEs to add to this distribution, {subdomain}.{domain} will be added automatically"
  type        = list
  default     = []
}

variable "price_class" {
  description = "Price class for this distribution. One of 'PriceClass_All', 'PriceClass_200', 'PriceClass_100', https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html"
  type        = string
  default     = "PriceClass_All"
}

variable "origins" {
  description = "Allows for defining additional Origins, by default we add an origin with the domain name as key, if not an S3 origin: add s3 = false in the object"
  type        = map(any)
  default     = {}
}

variable "default_cache_behavior" {
  description = "default cache behaviour, will be use as base for other cache behaviors"
  type = map(any)
  default = {
    viewer_protocol_policy     = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
    min_ttl         = 0
    default_ttl     = 3600
    max_ttl         = 86400
  }
}

variable "ordered_cache_behavior" {
  description = "These objects will be merged with default cache behaviour"
  type = list(any)
  default = []
}

