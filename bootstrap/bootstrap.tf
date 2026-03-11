terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.state_region
}

#### Variables

variable "unique_domain" {
  description = "Unique reverse domain with dashes for S3 bucket prefix (e.g., com-glenjarvis)"
  type        = string
}

variable "account" {
  description = "AWS Account name where state will be stored (e.g., prod, stage, demo)"
  type        = string
}

variable "state_region" {
  description = "AWS Region where the state will be stored"
  type        = string
}

variable "k8s_region" {
  description = "AWS Region where the k8s cluster will be created"
  type        = string
  default     = ""
}

locals {
  k8s_region   = var.k8s_region != "" ? var.k8s_region : var.state_region
  state_bucket = "${var.unique_domain}-${var.account}-terraform-state"
}

### Resources

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_s3_bucket_versioning" "versioning_enable" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_db_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "bootstrap_s3_save_state" {
  description = "Command to save state for future use"
  value       = <<-EOF
    # Save a backup of the state in the S3 bucket you just created:
    aws s3 cp terraform.tfstate "s3://${local.state_bucket}/global/bootstrap/"
    EOF
}


output "project_s3_configuration" {
  description = "A user friendly output to configure AWS S3 backend"
  value       = <<-EOF
    # Use this snippet when configuring your AWS S3 backend
    # for the rest of this project (Not this directory)
    backend "s3" {
        bucket         = "${local.state_bucket}"
        key            = "global/k8s/terraform.tfstate"
        region         = "${local.k8s_region}"
        dynamodb_table = "terraform-lock"
        encrypt        = true
    }
    EOF
}
