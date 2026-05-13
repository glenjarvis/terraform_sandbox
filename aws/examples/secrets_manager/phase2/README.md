# Phase 2 — Populate Secrets

This is a manual step, not a Terraform step. Secret values are entered directly via
the AWS CLI so they never touch Terraform state.

Complete this phase after Phase 1 and before running Phase 3.

## Populate the JSON blob secret

Create a local credentials file (do not commit this file):

```bash
vi tmp_file.json
```

Contents:

```json
{
  "username": "myuser",
  "password": "FINDME!12345678",
  "db_name": "demo",
  "host": "db.example.com"
}
```

```bash
aws secretsmanager put-secret-value \
  --secret-id demo/app/db_credentials \
  --secret-string file://tmp_file.json

rm tmp_file.json
```

## Populate the plain string secret

```bash
read -s -p "Enter DB password: " DB_PASSWORD_SECRET

aws secretsmanager put-secret-value \
  --secret-id demo/app/db_password \
  --secret-string "$DB_PASSWORD_SECRET"

unset DB_PASSWORD_SECRET
```

## Verify both secrets are populated

```bash
aws secretsmanager get-secret-value \
  --secret-id demo/app/db_credentials \
  --query SecretString \
  --output text | jq .

aws secretsmanager get-secret-value \
  --secret-id demo/app/db_password \
  --query SecretString \
  --output text
```

Once both secrets return values, proceed to Phase 3.
