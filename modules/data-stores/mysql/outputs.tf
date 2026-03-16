
output "arn" {
  description = "The ARN of the database"
  value       = aws_db_instance.aws_rds_instance.arn
}

output "address" {
  description = "The address of the database"
  value       =  aws_db_instance.aws_rds_instance.address 
}

output "port" {
  description = "The port of the database"
  value       =  aws_db_instance.aws_rds_instance.port
}
