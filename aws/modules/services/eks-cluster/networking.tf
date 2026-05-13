# Note: This module uses the default VPC for simplicity. A production EKS
# cluster should use a dedicated VPC with proper CIDR planning and subnet tagging.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

