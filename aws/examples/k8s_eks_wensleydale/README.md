# K8s EKS Wensleydale Example

Provisions an EKS cluster on AWS and deploys a cheese-themed web application to it, using
the [`eks-cluster`](../../modules/services/eks-cluster/) and
[`k8s_app`](../../modules/k8s_app/) modules.

## What it does

- Creates an EKS cluster (`wensleydale-eks`) with 1–2 `t3.small` nodes
- Deploys the `errm/cheese:wensleydale` image (2 replicas) to the cluster
- Configures both the AWS and Kubernetes providers in a single workspace

> **Note:** The Kubernetes provider is initialized using live output from the EKS cluster
> module. This is a demo of how to use a multi-provider scenario. However,
> building the EKS cluster AND deploying in the same Terraform project is a
> **TERRIBLE** idea for production.

> Per HashiCorp guidance, this pattern can cause intermittent errors during first
> apply — re-running `terraform apply` resolves it.

## Prerequisites

- AWS CLI with credentials configured
- `kubectl` installed

## Usage

```bash
terraform init
terraform apply
```

After apply, use the `kubectl_cmd` output to add the cluster context to your kubeconfig.

## Outputs

| Output       | Description                                        |
|--------------|----------------------------------------------------|
| `kubectl_cmd`| Command to add the EKS cluster context to kubectl  |
