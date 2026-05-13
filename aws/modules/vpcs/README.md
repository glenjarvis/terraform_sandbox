# Module: vpcs

Reusable module that creates a public VPC with subnets across multiple availability zones
and an internet gateway.

> **Note:** Subnets are public and instances will receive public IPs. This is intentional
> for sandbox experimentation without VPN setup — not suitable for production.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpcs"

  project     = "my-project"
  environment = "dev"
}
```

## Inputs

| Name          | Description                                            | Type          | Default          | Required |
|---------------|--------------------------------------------------------|---------------|------------------|----------|
| `project`     | Project name - used in resource tags and naming        | `string`      | `"default"`      | no       |
| `environment` | Deployment environment (e.g. `dev`, `stage`, `prod`)   | `string`      | -                | yes      |
| `az_count`    | Number of availability zones to create subnets in (1–4)| `number`      | `3`              | no       |
| `cidr_block`  | CIDR block for the VPC                                 | `string`      | `"10.0.10.0/24"` | no       |
| `tags`        | Additional tags to merge onto all resources            | `map(string)` | `{}`             | no       |

## Outputs

| Name         | Description                                |
|--------------|--------------------------------------------|
| `vpc_id`     | ID of the created VPC                      |
| `subnet_ids` | List of subnet IDs (one per AZ)            |
| `subnet_azs` | List of availability zones for each subnet |
