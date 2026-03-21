# Phase 1 — Create Secret Containers

Creates two empty secret containers in AWS Secrets Manager. Values are not set here;
they are populated manually in Phase 2.

## What it does

- Creates two secret containers in AWS Secrets Manager:
  - `demo/app/db_credentials` — a JSON blob secret (e.g. database connection details)
  - `demo/app/db_password` — a plain string secret (e.g. just database password)
- Outputs the ARN of each secret

## Prerequisites

- AWS CLI with credentials configured
- Terraform >= 1.14

## Usage

```bash
terraform init
terraform apply
```

## Outputs

| Output               | Description                      |
|----------------------|----------------------------------|
| `db_credentials_arn` | ARN of the db_credentials secret |
| `db_password_arn`    | ARN of the db_password secret    |
