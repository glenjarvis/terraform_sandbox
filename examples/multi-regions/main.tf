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
  alias  = "aws_east_region"
}

provider "aws" {
  region = "us-west-2"
  alias  = "aws_west_region"
}

locals {
  canonical_id = "099720109477"
  ubuntu_image_filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server*"
}

data "aws_region" "aws_east_region" {
  provider = aws.aws_east_region
}

data "aws_region" "aws_west_region" {
  provider = aws.aws_west_region
}

data "aws_ami" "aws_east_canonical_ami" {
  provider = aws.aws_east_region

  most_recent = true
  owners = [local.canonical_id]

  filter {
    name = "name"
    values = [local.ubuntu_image_filter]
  }
}

data "aws_ami" "aws_west_canonical_ami" {
  provider = aws.aws_west_region

  most_recent = true
  owners = [local.canonical_id]

  filter {
    name = "name"
    values = [local.ubuntu_image_filter]
  }
}

output "aws_east_region" {
  description = "Name of the East Coast Region"
  value       = data.aws_region.aws_east_region.region
}

output "aws_east_ami" {
  description = "Name of the East Coast Canonical AMI"
  value       = data.aws_ami.aws_east_canonical_ami.id
}

output "aws_west_region" {
  description = "Name of the West Coast Region"
  value       = data.aws_region.aws_west_region.region
}

output "aws_west_ami" {
  description = "Name of the West Coast Canonical AMI"
  value       = data.aws_ami.aws_west_canonical_ami.id
}
