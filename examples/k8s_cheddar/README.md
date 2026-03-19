# K8s Cheddar Example

Deploys a cheese-themed web application to a local Kubernetes cluster using the reusable
[`k8s_app`](../../modules/k8s_app/) module.

## What it does

- Creates a Kubernetes Deployment running the `errm/cheese:cheddar` image (2 replicas)
- Exposes it via a Kubernetes Service
- Targets the `docker-desktop` context in your local kubeconfig

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Kubernetes enabled
- `kubectl` configured with a `docker-desktop` context

## Usage

```bash
terraform init
terraform apply
```

## Outputs

| Output     | Description      |
|------------|------------------|
| `endpoint` | Service endpoint |
