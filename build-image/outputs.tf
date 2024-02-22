output "aws_ecr_repo_url" {
  value = aws_ecr_repository.repository[var.repository_name].repository_url
}

output "aws_ecr_repo_arn" {
  value = aws_ecr_repository.repository[var.repository_name].arn
}