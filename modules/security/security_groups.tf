# Dependency: VPC created first. Passed via input

locals {
  anywhere = ["0.0.0.0/0"]

  protocols = {
    tcp = "tcp"
    udp = "udp"
    any = -1
  }

  ports = {
    any   = 0
    ssh   = 22
    http  = 80
    https = 443
    dns   = 53
  }

  types = {
    ingress = "ingress"
    egress  = "egress"
  }
}

resource "aws_security_group" "node_access" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-node-access"
    Project     = var.project
    Environment = var.environment
  })
}

resource "aws_security_group_rule" "allow_ssh_ingres" {
  description       = "Allow incomming ssh"
  security_group_id = aws_security_group.node_access.id
  type              = local.types.ingress
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  from_port         = local.ports.ssh
  to_port           = local.ports.ssh
  protocol          = local.protocols.tcp
}

resource "aws_security_group_rule" "allow_https_egress" {
  description       = "Allow outbound HTTPS (image pulls, AWS APIs)"
  security_group_id = aws_security_group.node_access.id
  type              = local.types.egress
  protocol          = local.protocols.tcp
  from_port         = local.ports.https
  to_port           = local.ports.https
  cidr_blocks       = local.anywhere
}

resource "aws_security_group_rule" "allow_http_egress" {
  description       = "Allow outbound HTTP (package downloads)"
  security_group_id = aws_security_group.node_access.id
  type              = local.types.egress
  from_port         = local.ports.http
  to_port           = local.ports.http
  protocol          = local.protocols.tcp
  cidr_blocks       = local.anywhere
}

resource "aws_security_group_rule" "allow_dns_udp_egress" {
  description       = "Allow outbound DNS (UDP)"
  security_group_id = aws_security_group.node_access.id
  type              = local.types.egress
  from_port         = local.ports.dns
  to_port           = local.ports.dns
  protocol          = local.protocols.udp
  cidr_blocks       = local.anywhere
}

resource "aws_security_group_rule" "allow_dns_tcp_egress" {
  description       = "Allow outbound DNS (TCP, for large responses)"
  security_group_id = aws_security_group.node_access.id
  type              = local.types.egress
  cidr_blocks       = local.anywhere
  from_port         = local.ports.dns
  to_port           = local.ports.dns
  protocol          = local.protocols.tcp
}

output "security_group_id" {
  value = aws_security_group.node_access.id
}
