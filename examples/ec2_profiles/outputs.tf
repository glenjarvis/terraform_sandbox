output "role_name" {
  description = "Name of the auto-generated role"
  value       = aws_iam_role.instance_assume_role.name
}

output "ssh_command" {
  description = "Short cut command to quickly ssh to sandbox EC2 instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem admin@${aws_instance.sandbox_instance.public_ip}"
}

# Note: This uses the IMDSv1 endpoint for simplicity:
#
#   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>
#
# In production, use IMDSv2, which requires fetching a session token first:
#
#   TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
#     -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
#
#   curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
#     http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>
#
output "demo_creds" {
  description = "Command to pull temporary credentials"
  value       = "curl http://169.254.169.254/latest/meta-data/iam/security-credentials/${aws_iam_role.instance_assume_role.name}"
}