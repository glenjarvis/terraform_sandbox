output "db_password_arn" {
  description = "ARN of the db_password secret - use this to grant IAM access to the secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_credentials_arn" {
  description = "ARN of the db_credentials secret - use this to grant IAM access to the secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
