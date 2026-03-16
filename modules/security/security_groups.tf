# Dependency: VPC created first. Passed via input

locals {
  anywhere = ["0.0.0.0/0"]

  ports = {
    ssh   = 22
    http  = 80
    https = 443
    dns   = 53
  }
}

resource "aws_security_group" "node_access" {
  vpc_id = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = local.ports.ssh
    to_port     = local.ports.ssh
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    description = "Allow outbound HTTPS (image pulls, AWS APIs)"
    from_port   = local.ports.https
    to_port     = local.ports.https
    protocol    = "tcp"
    cidr_blocks = local.anywhere
  }

  egress {
    description = "Allow outbound HTTP (package downloads)"
    from_port   = local.ports.http
    to_port     = local.ports.http
    protocol    = "tcp"
    cidr_blocks = local.anywhere
  }

  egress {
    description = "Allow outbound DNS (UDP)"
    from_port   = local.ports.dns
    to_port     = local.ports.dns
    protocol    = "udp"
    cidr_blocks = local.anywhere
  }

  egress {
    description = "Allow outbound DNS (TCP, for large responses)"
    from_port   = local.ports.dns
    to_port     = local.ports.dns
    protocol    = "tcp"
    cidr_blocks = local.anywhere
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-node-access"
    Project     = var.project
    Environment = var.environment
  })
}

output "security_group_id" {
  value = aws_security_group.node_access.id
}
