output "role_name" {
  description = "Name of the auto-generated role"
  value       = aws_iam_role.instance_assume_role.name
}

output "ssh_command" {
  description = "Short cut command to quickly ssh to sandbox EC2 instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem admin@${aws_instance.sandbox_instance.public_ip}"
}

output "demo_creds" {
  description = "Commnd to pull temporary credentials"
  value       = "curl http://169.254.169.254/latest/meta-data/iam/security-credentials/${aws_iam_role.instance_assume_role.name}"
}