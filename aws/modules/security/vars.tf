variable "project" {
  description = "Name of project using security group"
  type        = string
  default     = "default"

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "project must be a non-empty string."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, stage, prod)."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string (e.g. dev, stage, prod)."
  }
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks (e.g. [\"203.0.113.5/32\"]) allowed to access nodes"
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "Each entry must be a valid CIDR block (e.g. \"203.0.113.5/32\")."
  }
}

variable "vpc_id" {
  description = "ID of previously created Virtual Private Cloud (VPC)"
  type        = string
}

variable "tags" {
  description = "Tags for security group resources"
  type        = map(string)
  default = {}
}
