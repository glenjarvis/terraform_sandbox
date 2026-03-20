# Secrets Manager Example

Demonstrates how to create AWS Secrets Manager secret containers with Terraform and
populate their values via the CLI - keeping secrets out of source control.

## What it does

- Creates two secret containers in AWS Secrets Manager:
  - `demo/app/api_key` — a plain string secret (e.g. an API key)
  - `demo/app/db_credentials` — a JSON blob secret (e.g. database connection details)
- Outputs the ARN of each secret

Values are not set by Terraform. After `terraform apply`, populate them via the CLI
as shown below.

## Prerequisites

- AWS CLI with credentials configured
- Terraform >= 1.14

## Usage

### 1. Apply

```bash
terraform init
terraform apply
```

### 2. Populate the plain string secret

```bash
read -e -p "Enter API key: " API_KEY_SECRET

aws secretsmanager put-secret-value \
  --secret-id demo/app/api_key \
  --secret-string "$API_KEY_SECRET"

unset API_KEY_SECRET
```

### 3. Populate the JSON blob secret

Create a local credentials file (do not commit this file)
`vi tmp_file.json`

Contents:

```json
{
  "username": "myuser",
  "password": "mypassword",
  "host": "db.example.com"
}
```

```bash
aws secretsmanager put-secret-value \
  --secret-id demo/app/db_credentials \
  --secret-string file://tmp_file.json
```

### 4. Retrieve a secret value

```bash
# Plain string
aws secretsmanager get-secret-value \
  --secret-id demo/app/api_key \
  --query SecretString \
  --output text

# JSON blob (pipe through jq to pretty-print)
aws secretsmanager get-secret-value \
  --secret-id demo/app/db_credentials \
  --query SecretString \
  --output text | jq .
```

### 5. Tear down

```bash
terraform destroy
```

Both secrets have `recovery_window_in_days = 0`, so they are deleted immediately
rather than entering the default 30-day recovery window.

## Outputs

| Output                | Description                       |
| --------------------- | --------------------------------- |
| `api_key_arn`         | ARN of the api_key secret         |
| `db_credentials_arn`  | ARN of the db_credentials secret  |

## Cost

Secrets Manager charges $0.40 per secret per month, prorated to the hour. For a
short learning exercise, the cost is fractions of a cent.
