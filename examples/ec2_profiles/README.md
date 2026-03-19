# EC2 Profiles Example

Demonstrates an EC2 instance with an IAM instance profile, allowing the instance to make AWS
API calls without embedded credentials.

## What it does

- Creates a VPC with a public subnet
- Attaches a security group allowing SSH from your IP only
- Launches a Debian EC2 instance with an IAM instance profile
- The instance profile grants `ec2:*` permissions (sandbox only — not for production)

## Prerequisites

- Bootstrap S3 backend must be set up first — see [`bootstrap/`](../../bootstrap/README.md)
- A key pair must exist in your AWS account; set `ssh_key_name` in `terraform.tfvars` (defaults to `terraform_sandbox.pem`)

## Setup

1. Copy the example tfvars file and fill in your IP:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars — replace YOUR.IP.HERE with: curl ifconfig.me
   ```

2. Run Terraform:

   ```bash
   terraform init
   terraform apply
   ```

## Outputs

| Output        | Description                                                    |
|---------------|----------------------------------------------------------------|
| `role_name`   | Name of the auto-generated IAM role                            |
| `ssh_command` | Ready-to-run SSH command for the instance                      |
| `demo_creds`  | Fetch temporary credentials from the instance metadata service |
