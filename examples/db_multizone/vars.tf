variable "db_username" {
  description = "Username for the DB"
  type        = string
  sensitive   = true
  default     = "multi"
}

variable "db_password" {
  description = "Password for the DB"
  type        = string
  sensitive   = true
}

