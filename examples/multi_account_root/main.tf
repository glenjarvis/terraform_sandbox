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

provider "aws" {
  region = "us-east-2"
  alias  = "glenjarvis_com_website"

  assume_role {
    role_arn = "arn:aws:iam::460862207797:role/OrganizationAccountAccessRole"
  }
}

data "aws_caller_identity" "account_management" {
  provider = aws.management_account
}

data "aws_caller_identity" "account_website_glenjarvis_com" {
  provider = aws.glenjarvis_com_website
}
