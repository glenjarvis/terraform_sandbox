# Module: services/eks-cluster

Reusable module that provisions an EKS cluster with a managed node group, using the
account's default VPC and subnets.

Creates the following AWS resources:
- EKS cluster (Kubernetes 1.35)
- Managed node group with configurable instance types and scaling
- IAM roles and policy attachments for the cluster and node group

## Usage

```hcl
module "eks_cluster" {
  source = "../../modules/services/eks-cluster"

  name           = "my-eks-cluster"
  min_size       = 1
  max_size       = 3
  desired_size   = 2
  instance_types = ["t3.small"]
}
```

## Inputs

| Name             | Description                                        | Type           | Required |
|------------------|----------------------------------------------------|----------------|----------|
| `name`           | Name of the EKS cluster and node group             | `string`       | yes      |
| `min_size`       | Minimum number of nodes in the node group          | `number`       | yes      |
| `max_size`       | Maximum number of nodes in the node group          | `number`       | yes      |
| `desired_size`   | Desired number of nodes in the node group          | `number`       | yes      |
| `instance_types` | EC2 instance types for the node group              | `list(string)` | yes      |

## Outputs

| Name                           | Description                                                     |
|--------------------------------|-----------------------------------------------------------------|
| `cluster_name`                 | Name of the EKS cluster                                         |
| `cluster_arn`                  | ARN of the EKS cluster                                          |
| `cluster_endpoint`             | API server endpoint — used to configure the K8s provider        |
| `cluster_certificate_authority`| Certificate authority data — used to configure the K8s provider |
