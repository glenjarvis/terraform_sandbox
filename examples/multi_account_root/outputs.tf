output "account_management_id" {
  description = "The ID of the parent (management) AWS Account"
  value       = data.aws_caller_identity.account_management.id
}

output "account_website_glenjarvis_com_id" {
  description = "The ID of the glenjarivs.com AWS account"
  value       = data.aws_caller_identity.account_website_glenjarvis_com.id
}
