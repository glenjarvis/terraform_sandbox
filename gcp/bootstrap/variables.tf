variable "project_id" {
  description = "GCP project ID where the state bucket will be created"
  type        = string
}

variable "region" {
  description = "GCP region for the state bucket (e.g., us-central1)"
  type        = string
}

variable "unique_prefix" {
  description = "Unique prefix for the GCS bucket name (e.g., com-glenjarvis-sandbox)"
  type        = string
}
