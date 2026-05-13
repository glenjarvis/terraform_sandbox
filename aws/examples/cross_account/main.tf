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
  alias  = "management_account"
}

variable "org_member_account_id" {
  description = "AWS account ID of the member account to assume into via OrganizationAccountAccessRole"
  type        = string
}

provider "aws" {
  region = "us-east-2"
  alias  = "other_account"

  assume_role {
    role_arn = "arn:aws:iam::${var.org_member_account_id}:role/OrganizationAccountAccessRole"
  }
}

data "aws_caller_identity" "account_management" {
  provider = aws.management_account
}

data "aws_caller_identity" "account_other" {
  provider = aws.other_account
}
