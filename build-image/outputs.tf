output "aws_ecr_repo_url" {
  value = aws_ecr_repository.repository[format("%s", var.repository_name)].repository_url
}

output "aws_ecr_repo_arn" {
  value = aws_ecr_repository.repository[format("%s", var.repository_name)].arn
}
output "aws_ecr_cache_repo_url" {
  value = var.cache ? aws_ecr_repository.repository[format("%s/cache", var.repository_name)].repository_url : ""
}

output "aws_ecr_cache_repo_arn" {
  value = var.cache ? aws_ecr_repository.repository[format("%s/cache", var.repository_name)].arn : ""
}