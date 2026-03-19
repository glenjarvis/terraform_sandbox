# Terraform Sandbox

Personal sandbox for exploring Terraform across a range of scenarios.

I often use this repo:
- As a sandbox to run little experiments when testing Terraform
- As a quick reference (previous examples) when writing similar Terraform configurations

Not intended for production use.

## Examples

- [`bootstrap/`](bootstrap/)                       — S3 backend setup; run first for examples that use remote state
- [`cross_account/`](examples/cross_account/)      — Assume a role in another AWS account without separate credentials
- [`db_multizone/`](examples/db_multizone/)        — MySQL RDS with cross-region read replica
- [`ec2_profiles/`](examples/ec2_profiles/)        — EC2 with IAM instance profile *(uses remote state)*
- [`github_to_aws/`](examples/github_to_aws/)      — IAM role + OIDC provider for GitHub Actions authentication
- [`k8s_cheddar/`](examples/k8s_cheddar/)          — Kubernetes deployment (cheese-themed image)
- [`k8s_eks_wensleydale/`](examples/k8s_eks_wensleydale/) — EKS cluster with Kubernetes deployment (multiple-provider; cheese-themed image)
- [`multi_regions/`](examples/multi_regions/)      — Multi-region provider configuration
- [`oidc/`](examples/oidc/)                        — GitHub OIDC provider setup for AWS authentication

## Modules

- [`data_stores/mysql/`](modules/data_stores/mysql/) — Reusable RDS MySQL module with Replication
- [`k8s_app/`](modules/k8s_app/)                     — Kubernetes Deployment and Service
- [`security/`](modules/security/)                   — Security groups
- [`services/eks-cluster/`](modules/services/eks-cluster/) — EKS cluster with networking and IAM
- [`vpcs/`](modules/vpcs/)                           — VPC with subnets and internet gateway

## Prerequisites

- Terraform >= 1.14
- AWS CLI with credentials configured
- `kubectl` (EKS examples only)

## Getting Started

### Examples that use remote state

`ec2_profiles` stores Terraform state in S3. Run `bootstrap/` first — see its
[README](bootstrap/README.md) for setup instructions. Then follow the example's own README.

### Examples with local state

All other examples use local state:

```bash
cd examples/<name>
terraform init
terraform apply
```
