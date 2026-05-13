terraform {
  required_version = ">= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

#### Resources

resource "google_storage_bucket" "terraform_state" {
  name     = "${var.unique_prefix}-terraform-state"
  location = var.region

  force_destroy = false

  versioning {
    enabled = true
  }

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}

#### Outputs

output "bootstrap_gcs_save_state" {
  description = "Command to save a backup of bootstrap state into the bucket you just created"
  value       = <<-EOF
    # Save a backup of the state in the GCS bucket you just created:
    gsutil cp terraform.tfstate gs://${google_storage_bucket.terraform_state.name}/global/bootstrap/
    EOF
}

output "project_gcs_configuration" {
  description = "A user friendly output to configure GCS backend for future GCP examples"
  value       = <<-EOF
    # Use this snippet when configuring your GCS backend
    # for future examples in gcp/examples/ (not this directory)
    backend "gcs" {
      bucket = "${google_storage_bucket.terraform_state.name}"
      prefix = "global/<example-name>"
    }
    EOF
}
