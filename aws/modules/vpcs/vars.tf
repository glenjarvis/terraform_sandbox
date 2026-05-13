variable "project" {
  description = "Name of project using VPC"
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

variable "az_count" {
  # Note: If a region has less than this number of availability
  # zones, we only create what is available in region
  # Note: For simplicity, this is constrained to 4 or less
  # even though some regions can have 6 AZs
  description = "Number of availability zones to use"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 4
    error_message = "az_count must be between 1 and 4 (cidr_bits = 2 supports max 4 subnets)."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.10.0/24"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR block (e.g., 10.0.10.0/24)"
  }
}

variable "tags" {
  description = "Tags for VPC"
  type        = map(string)
  default     = {}
}
