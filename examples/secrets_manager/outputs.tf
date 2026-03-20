output "api_key_arn" {
  description = "ARN of the api_key secret - use this to grant IAM access to the secret"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "db_credentials_arn" {
  description = "ARN of the db_credentials secret - use this to grant IAM access to the secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
