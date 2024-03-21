locals {
  service_name  = join("-", compact([var.service, var.component]))
  tags = merge( var.tags, { Environment = var.environment, Role =	"Cloudfront", Service = local.service_name, ManagedBy = "Terraform Automated Github Action" })

  # origins
  origins = { for id, config in merge({ (local.fqdn) = {} }, jsondecode(var.origins)): 
    id => merge(
      try(config.s3, true) ? {
        domain_name = data.aws_s3_bucket.bucket.bucket_regional_domain_name
        origin_access_control = "s3_oac"
      }:{}, 
      config
    )
  }

  # cache behaviors
  default_cache_behavior = merge({ target_origin_id = local.fqdn }, jsondecode(var.default_cache_behavior))
  ordered_cache_behavior = [ for config in jsondecode(var.ordered_cache_behavior): merge(local.default_cache_behavior, config) ]

  # domain
  fqdn   = format("%s.%s", var.subdomain, local.domain)
  domain = var.domain
}

#################
## Data Gathering
#################
data "aws_s3_bucket" "bucket" {
  bucket = var.bucket_id
}

data "aws_route53_zone" "domain" {
  name = var.domain
}

#################
## Certificate
#################
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  providers = {
    aws = aws.us-east-1
  }

  domain_name = local.fqdn
  zone_id     = data.aws_route53_zone.domain.zone_id

  validation_method = "DNS"

  wait_for_validation = true

  tags = merge({ Name = local.fqdn, Role = "Certificate" }, local.tags)
}

#################
## DNS Record
#################
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = data.aws_route53_zone.domain.zone_id

  records = [
    {
      name    = "cloudfront"
      type    = "A"
      alias   = {
        name    = module.cdn.cloudfront_distribution_domain_name
        zone_id = module.cdn.cloudfront_distribution_hosted_zone_id
        evaluate_target_health = true
      }
    },
  ]
}

#################
## Cloudfront
#################
module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = concat([local.fqdn],var.domain_aliases)

  comment             = var.description
  price_class         = var.price_class
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  default_root_object = "index.html"
  tags                = local.tags

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin                 = local.origins
  default_cache_behavior = local.default_cache_behavior
  ordered_cache_behavior = local.ordered_cache_behavior

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response = var.custom_error_responses
}