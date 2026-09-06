output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.hello_container.function_name
}

output "ecr_repository_url" {
  description = "Push images here before applying/updating the function"
  value       = aws_ecr_repository.hello_container.repository_url
}

output "log_group" {
  description = "CloudWatch log group holding this function's logs"
  value       = aws_cloudwatch_log_group.hello_container.name
}

output "invoke_command" {
  description = "Ready-to-run command that invokes the function and prints the response"
  value       = <<-EOT
    aws lambda invoke \
      --function-name ${aws_lambda_function.hello_container.function_name} \
      --region us-west-2 \
      --cli-binary-format raw-in-base64-out \
      --payload '{"name": "Glen"}' \
      /dev/stdout
  EOT
}
