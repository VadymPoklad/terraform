output "db_endpoint" {
  description = "Database endpoint"
  value       = module.db.db_endpoint
}

output "db_secret_arn" {
  description = "Secret ARN in AWS Secrets Manager"
  value       = module.db.db_secret_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ec2.alb_dns_name
}