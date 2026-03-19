terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # Replace bucket with your own — see bootstrap/README.md for setup instructions.
  backend "s3" {
    bucket       = "com-glenjarvis-demo-terraform-state"
    key          = "global/github_oidc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }

}

provider "aws" {
  region = "us-west-2"
}
