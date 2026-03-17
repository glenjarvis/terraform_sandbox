terraform {
  required_version = "~> 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}


module "eks_cluster" {
  source = "../../modules/services/eks-cluster"

  name         = "cheddar-eks"
  min_size     = 1
  max_size     = 2
  desired_size = 1

  instance_types = ["t3.small"]
}
