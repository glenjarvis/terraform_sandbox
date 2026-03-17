data "aws_region" "current_region" {}

output "kubectl_cmd" {
  description = "How to add a K8s context for cluster"
  value = "aws eks update-kubeconfig --region ${data.aws_region.current_region.region} --name ${module.eks_cluster.cluster_name}"
  
}
