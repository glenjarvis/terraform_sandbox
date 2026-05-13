locals {
  status = kubernetes_service_v1.app.status
}

output "service_endpoint" {
  description = "The K8s Service endpoint"
  value = try(
    "http://${local.status[0]["load_balancer"][0]["ingress"][0]["hostname"]}",
    "(error parsing hostname for status)"
  )
}