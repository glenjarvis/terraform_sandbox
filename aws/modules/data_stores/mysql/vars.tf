variable "project" {
  description = "Name of the database project. Will be used with name prefix"
  type        = string
  default     = "generic"

  validation {
    condition     = length(var.project) > 0
    error_message = "Project name must be non-empty string"
  }
}

variable "db_name" {
  description = "Name for the DB"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Username for the DB"
  type        = string
  sensitive   = true
  default     = null
}

variable "db_password" {
  description = "Password for the DB"
  type        = string
  sensitive   = true
  default     = null
}


variable "backup_retention_period" {
  description = "Days to retain backups. Must be > 0 to enable replication"
  type        = number
  default     = null

  validation {
    condition     = var.backup_retention_period == null || var.backup_retention_period >= 0
    error_message = "backup_retention_period must be null or an integer"
  }
}

variable "replicate_source_db" {
  description = "If specified, replicate the RDS database at the given ARN."
  type        = string
  default     = null

  validation {
    condition     = var.replicate_source_db == null || length(var.replicate_source_db) > 0
    error_message = "backup_retention_period must be null or a string with  length > 0"
  }
}
