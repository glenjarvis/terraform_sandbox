# DB Multizone Example

Demonstrates a MySQL RDS instance in one region with a cross-region read replica, using the
reusable [`data_stores/mysql`](../../modules/data_stores/mysql/) module.

## What it does

- Creates a primary MySQL RDS instance in `us-east-2`
- Creates a read replica of that instance in `us-west-2`
- Uses two aliased AWS providers to manage resources in both regions simultaneously

## Prerequisites

- AWS CLI with credentials configured

## Setup

Supply the database password at apply time (username defaults to `multi`):

```bash
terraform init
terraform apply -var="db_password=<your-password>"
```

Or create a `terraform.tfvars` file (gitignored):

```hcl
db_password = "your-password"
```

## Outputs

| Output            | Description                              |
|-------------------|------------------------------------------|
| `primary_address` | Endpoint for the primary database        |
| `primary_port`    | Port the primary database listens on     |
| `primary_arn`     | ARN of the primary database              |
| `replica_address` | Endpoint for the read replica            |
| `replica_port`    | Port the read replica listens on         |
| `replica_arn`     | ARN of the read replica                  |
