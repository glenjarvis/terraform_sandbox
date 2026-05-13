
locals {
  environment = "dev"
  project     = "sandbox-ec2-profile"
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Official Debian AWS account

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source = "../../modules/vpcs"

  project     = local.project
  environment = local.environment
}

module "security_group" {
  source = "../../modules/security"

  project                 = local.project
  environment             = local.environment
  vpc_id                  = module.vpc.vpc_id
  allowed_ssh_cidr_blocks = var.allowed_ssh_cidr_blocks
}

resource "aws_iam_role" "instance_assume_role" {
  name_prefix        = local.project
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "control_ec2" {
  role   = aws_iam_role.instance_assume_role.name
  policy = data.aws_iam_policy_document.control_ec2.json
}

# Note: This is WAY TOO broad for a production situation.
# a. Make specific actions (e.g, "ec2:StartInstances")
# b. Add a tagged condition (e.g., See commented section)
data "aws_iam_policy_document" "control_ec2" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:ResourceTag/Project"
    #   values   = [local.project]
    # }
  }
}

resource "aws_iam_instance_profile" "control_ec2" {
  role = aws_iam_role.instance_assume_role.name
}

resource "aws_instance" "sandbox_instance" {
  ami                    = data.aws_ami.debian.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.subnet_ids[0]
  vpc_security_group_ids = [module.security_group.security_group_id]
  key_name               = var.ssh_key_name

  iam_instance_profile = aws_iam_instance_profile.control_ec2.name

  tags = {
    Project = local.project
  }
}
