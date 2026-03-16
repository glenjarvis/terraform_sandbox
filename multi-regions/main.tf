terraform {
  required_version = "~> 1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "aws-east-region"
}

provider "aws" {
  region = "us-west-2"
  alias  = "aws-west-region"
}

locals {
  canonical_id = "099720109477"
  ubuntu_image_filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server*"
}

data "aws_region" "aws-east-region" {
  provider = aws.aws-east-region
}

data "aws_region" "aws-west-region" {
  provider = aws.aws-west-region
}

data "aws_ami" "aws-east-canonical-ami" {
  provider = aws.aws-east-region

  most_recent = true
  owners = [local.canonical_id]

  filter {
    name = "name"
    values = [local.ubuntu_image_filter]
  }
}

data "aws_ami" "aws-west-canonical-ami" {
  provider = aws.aws-west-region

  most_recent = true
  owners = [local.canonical_id]

  filter {
    name = "name"
    values = [local.ubuntu_image_filter]
  }
}

output "aws-east-region" {
  description = "Name of the East Coast Region"
  value       = data.aws_region.aws-east-region.region
}

output "aws-east-ami" {
  description = "Name of the East Coast Canonical AMI"
  value       = data.aws_ami.aws-east-canonical-ami.id
}

output "aws-west-region" {
  description = "Name of the West Coast Region"
  value       = data.aws_region.aws-west-region.region
}

output "aws-west-ami" {
  description = "Name of the West Coast Canonical AMI"
  value       = data.aws_ami.aws-west-canonical-ami.id
}
