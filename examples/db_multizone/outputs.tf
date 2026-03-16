output "primary_address" {
  description = "Connect to the primary database at this endpoint"
  value       = module.primary-db.address
}

output "primary_port" {
  description = "The port th eprimary database is listening on"
  value       = module.primary-db.port
}

output "primary_arn" {
  description = "The ARN of the primary database"
  value       = module.primary-db.arn
}

output "replica_address" {
  description = "Connect to the replica database at this endpoint"
  value       = module.replica-db.address
}

output "replica_port" {
  description = "The port the replica database is listening on"
  value       = module.replica-db.port
}

output "replica_arn" {
  description = "The ARN of the replica database"
  value       = module.replica-db.arn
}
