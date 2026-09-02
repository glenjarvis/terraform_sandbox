# Terraform Sandbox

Personal sandbox for exploring and experimenting with Terraform across multiple cloud providers.

I often use this repo:
- As a sandbox to run little experiments when testing Terraform
- As a quick reference (previous examples) when writing similar Terraform configurations

Not intended for production use.

---

## AWS

### Bootstrap

- [`aws/bootstrap/`](aws/bootstrap/) — S3 backend setup; run first for AWS examples that use remote state

### Examples

- [`cross_account/`](aws/examples/cross_account/)           — Assume a role in another AWS account without separate credentials
- [`db_multizone/`](aws/examples/db_multizone/)             — MySQL RDS with cross-region read replica
- [`ec2_profiles/`](aws/examples/ec2_profiles/)             — EC2 with IAM instance profile *(uses remote state)*
- [`github_to_aws/`](aws/examples/github_to_aws/)           — GitHub Actions → AWS authentication via OIDC (no stored credentials)
- [`hello_lambda/`](aws/examples/hello_lambda/)             — Minimal Python Lambda, packaged and invoked from the CLI
- [`k8s_cheddar/`](aws/examples/k8s_cheddar/)               — Kubernetes deployment on Docker Desktop (cloud-agnostic)
- [`k8s_eks_wensleydale/`](aws/examples/k8s_eks_wensleydale/) — EKS cluster with Kubernetes deployment (cheese-themed image)
- [`multi_regions/`](aws/examples/multi_regions/)           — Multi-region provider configuration
- [`requests_lambda/`](aws/examples/requests_lambda/)       — Lambda importing `requests` from a layer instead of bundling it
- [`requests_layer/`](aws/examples/requests_layer/)         — Builds and publishes a Lambda layer containing `requests`
- [`secrets_manager/`](aws/examples/secrets_manager/)       — AWS Secrets Manager walkthrough (3-phase)

### Modules

- [`data_stores/mysql/`](aws/modules/data_stores/mysql/) — Reusable RDS MySQL module with replication
- [`k8s_app/`](aws/modules/k8s_app/)                     — Kubernetes Deployment and Service
- [`security/`](aws/modules/security/)                   — Security groups and rules
- [`services/eks-cluster/`](aws/modules/services/eks-cluster/) — EKS cluster with networking and IAM
- [`vpcs/`](aws/modules/vpcs/)                           — VPC with subnets and internet gateway

---

## GCP

### Bootstrap

- [`gcp/bootstrap/`](gcp/bootstrap/) — GCS bucket for Terraform remote state; run first for GCP examples that use remote state

---

## Azure

*(Coming soon)*

---

## Prerequisites

- Terraform >= 1.14
- **AWS examples**: AWS CLI with credentials configured
- **GCP examples**: `gcloud` CLI authenticated (`gcloud auth application-default login`)
- `kubectl` (EKS examples only)

## Getting Started

### AWS examples that use remote state

`ec2_profiles` and `github_to_aws` store Terraform state in S3. Run `aws/bootstrap/` first —
see its [README](aws/bootstrap/README.md) for setup instructions. Then follow the example's own README.

### GCP bootstrap

Run `gcp/bootstrap/` first to create the GCS state bucket before any GCP examples that use
remote state. See its [README](gcp/bootstrap/README.md) for setup instructions.

### Examples with local state

All other examples use local state:

```bash
cd aws/examples/<name>
terraform init
terraform apply
```
