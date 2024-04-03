output "bucket_arn" {
  value = module.s3-bucket.s3_bucket_arn
}

output "bucket_id" {
  value = module.s3-bucket.s3_bucket_id
}

output "cloudfront_oac_id" {
  value = var.cloudfront_origin_access_control ? aws_cloudfront_origin_access_control.oac["access"].id : ""
}
