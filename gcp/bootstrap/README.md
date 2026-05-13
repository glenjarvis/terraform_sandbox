# GCP Bootstrap

Creates a GCS bucket for storing Terraform remote state. Run this first before any GCP
examples that use a remote backend.

Mirrors the pattern established in [`aws/bootstrap/`](../aws/bootstrap/).

## Prerequisites

### 1. Create a GCP project

If you haven't already, create a project in the [GCP Console](https://console.cloud.google.com/)
and note the **Project ID** (not the display name).

### 2. Authenticate with gcloud

```bash
gcloud auth application-default login
```

This writes credentials that the Google Terraform provider will pick up automatically.

### 3. Enable the Cloud Storage API

```bash
gcloud services enable storage.googleapis.com --project=<your-project-id>
```

## Usage

Copy the example vars file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` is ignored by git and will not be committed. See
[`terraform.tfvars.example`](terraform.tfvars.example) for the variables and their descriptions.

Then initialize and apply:

```bash
cd gcp/bootstrap
terraform init
terraform apply
```

## After apply

The output `bootstrap_gcs_save_state` gives you a `gsutil` command to back up the bootstrap
state itself into the new bucket:

```bash
gsutil cp terraform.tfstate gs://<bucket-name>/global/bootstrap/
```

The output `project_gcs_configuration` gives you the `backend "gcs"` snippet to paste into
future GCP examples.

## Notes

- `force_destroy = false` and `prevent_destroy = true` protect the bucket from accidental deletion.
- Versioning is enabled so older state files are recoverable.
- `public_access_prevention = "enforced"` and `uniform_bucket_level_access = true` ensure
  the bucket is never accidentally made public.
- `recovery_window` is not applicable to GCS — bucket deletion is immediate once `force_destroy`
  is set to `true`, so the lifecycle guard here is the primary protection.
