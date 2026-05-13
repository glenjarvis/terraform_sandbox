# Module: k8s_app

Reusable module that creates a Kubernetes Deployment and LoadBalancer Service for a
containerized application.

## Usage

```hcl
module "my_app" {
  source = "../../modules/k8s_app"

  name           = "my-app"
  image          = "nginx:latest"
  container_port = 80
  replicas       = 2

  environment_variables = {
    ENV = "sandbox"
  }
}
```

## Inputs

| Name                   | Description                                    | Type          | Required |
|------------------------|------------------------------------------------|---------------|----------|
| `name`                 | Name used for all resources in this module     | `string`      | yes      |
| `image`                | Docker image to run                            | `string`      | yes      |
| `container_port`       | Port the container listens on                  | `number`      | yes      |
| `replicas`             | Number of pod replicas                         | `number`      | yes      |
| `environment_variables`| Environment variables to inject into the pod   | `map(string)` | no       |

## Outputs

| Name               | Description               |
|--------------------|---------------------------|
| `service_endpoint` | URL of the LoadBalancer service |
