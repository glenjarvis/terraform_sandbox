terraform {
  required_version = "~> v1.14.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

module "k8s_cheese" {
  source = "../../modules/k8s_app"

  name           = "cheesy"
  image          = "errm/cheese:cheddar"
  container_port = 80
  replicas       = 2
}
