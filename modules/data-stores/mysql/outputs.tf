
output "arn" {
  description = "The ARN of the database"
  value       = aws_db_instance.aws-rds-instance.arn
}

output "address" {
  description = "The address of the database"
  value       =  aws_db_instance.aws-rds-instance.address 
}

output "port" {
  description = "The port of the database"
  value       =  aws_db_instance.aws-rds-instance.port
}
