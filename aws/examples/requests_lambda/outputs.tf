output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.check_ip.function_name
}

output "layer_version_arn" {
  description = "The layer version this function resolved and attached to"
  value       = data.aws_lambda_layer_version.requests.arn
}

output "log_group" {
  description = "CloudWatch log group holding this function's logs"
  value       = aws_cloudwatch_log_group.check_ip.name
}

output "invoke_command" {
  description = "Ready-to-run command that invokes the function and prints the response"
  value       = <<-EOT
    aws lambda invoke \
      --function-name ${aws_lambda_function.check_ip.function_name} \
      --region us-west-2 \
      /dev/stdout
  EOT
}
