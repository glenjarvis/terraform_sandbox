# NOTE!!! This is a sandbox for testing ideas
#
# A better VPC should be used when exploring for realz

# TODO: Make a better sandbox example with a private VPC and a bastion host
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

