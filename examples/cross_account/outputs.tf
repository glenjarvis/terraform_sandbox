# Note: Account IDs are intentionally shown in plaintext here to demonstrate
# that the two accounts are distinct. In a production setup, outputs containing
# account IDs should be marked sensitive = true.

output "account_management_id" {
  description = "The ID of the parent (management) AWS Account"
  value       = data.aws_caller_identity.account_management.id
}

output "account_other_id" {
  description = "The ID of the other AWS account"
  value       = data.aws_caller_identity.account_other.id
}
