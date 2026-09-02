output "layer_name" {
  description = "Name consumers look the layer up by"
  value       = aws_lambda_layer_version.requests.layer_name
}

output "layer_version_arn" {
  description = "ARN of this specific published version - what a function attaches to"
  value       = aws_lambda_layer_version.requests.arn
}

output "layer_arn" {
  description = "ARN of the layer itself, without a version suffix"
  value       = aws_lambda_layer_version.requests.layer_arn
}

output "version" {
  description = "Version number, incremented by AWS on every publish"
  value       = aws_lambda_layer_version.requests.version
}
