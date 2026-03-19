variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the instance. See terraform.tfvars.example."
  type        = list(string)
}

variable "ssh_key_name" {
  description = "Name of previously created SSH key"
  type        = string
  default     = "terraform_sandbox.pem"
}
