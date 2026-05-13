
output "endpoint" {
  description = "Service Endpoint"
  value       = module.k8s_cheese.service_endpoint
}
