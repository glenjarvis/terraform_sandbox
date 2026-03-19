# Module: security

Reusable module that creates an AWS security group for EC2 node access.

**Ingress:** SSH from specified CIDR blocks only.
**Egress:** HTTPS, HTTP, and DNS (UDP + TCP) to anywhere.

## Usage

```hcl
module "security_group" {
  source = "../../modules/security"

  project                 = "my-project"
  environment             = "dev"
  vpc_id                  = module.vpc.vpc_id
  allowed_ssh_cidr_blocks = ["203.0.113.5/32"]
}
```

## Inputs

| Name                     | Description                                          | Type           | Required |
|--------------------------|------------------------------------------------------|----------------|----------|
| `project`                | Project name — used in resource tags and naming      | `string`       | yes      |
| `environment`            | Deployment environment (e.g. `dev`, `stage`, `prod`) | `string`       | yes      |
| `vpc_id`                 | ID of the VPC to attach the security group to        | `string`       | yes      |
| `allowed_ssh_cidr_blocks`| CIDR blocks permitted to SSH in (e.g. your IP `/32`) | `list(string)` | yes      |
| `tags`                   | Additional tags to merge onto the security group     | `map(string)`  | no       |

## Outputs

| Name                | Description                  |
|---------------------|------------------------------|
| `security_group_id` | ID of the created security group |
