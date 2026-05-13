# Multi-Regions Example

Demonstrates how to configure multiple aliased AWS providers targeting different regions
in a single Terraform workspace.

## What it does

- Configures two aliased AWS providers: `us-east-1` and `us-west-2`
- Looks up the most recent Ubuntu 24.04 ARM64 AMI in each region
- Outputs the region name and AMI ID for each

## Prerequisites

- AWS CLI with credentials configured

## Usage

```bash
terraform init
terraform apply
```

## Outputs

| Output            | Description                          |
|-------------------|--------------------------------------|
| `aws_east_region` | Name of the us-east-1 region         |
| `aws_east_ami`    | Latest Ubuntu 24.04 AMI in us-east-1 |
| `aws_west_region` | Name of the us-west-2 region         |
| `aws_west_ami`    | Latest Ubuntu 24.04 AMI in us-west-2 |
