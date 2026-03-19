output "account_management_id" {
  description = "The ID of the parent (management) AWS Account"
  value       = data.aws_caller_identity.account_management.id
}

output "account_other_id" {
  description = "The ID of the other AWS account"
  value       = data.aws_caller_identity.account_other.id
}
