output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_secret_arn" {
  description = "Secret ARN in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_secret.arn
}