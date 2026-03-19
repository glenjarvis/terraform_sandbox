# This is a sandbox/scratch deployment ONLY.  This is not for production:

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
#
# When using interpolation to pass credentials to the Kubernetes provider from other
# resources, these resources SHOULD NOT be created in the same Terraform module
# where Kubernetes provider resources are also used. This will lead to intermittent
# and unpredictable errors which are hard to debug and diagnose. The root issue
# lies with the order in which Terraform itself evaluates the provider
# blocks vs. actual resources.

terraform {
  required_version = "~> 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks_cluster.cluster_certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}


data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}


module "eks_cluster" {
  source = "../../modules/services/eks-cluster"

  name         = "wensleydale-eks"
  min_size     = 1
  max_size     = 2
  desired_size = 1

  instance_types = ["t3.small"]
}


module "wensleydale_webapp" {
  source = "../../modules/k8s_app"

  name           = "wensleydale-webapp"
  image          = "errm/cheese:wensleydale"
  replicas       = 2
  container_port = 80

  environment_variables = {
    PROVIDER = "Terraform"
    Cheese   = "wensleydale"
  }

  depends_on = [ module.eks_cluster ]
}
