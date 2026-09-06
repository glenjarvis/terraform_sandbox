# Hello Container Lambda Example

The container-image counterpart to [`hello_lambda/`](../hello_lambda/): the same greeting handler,
deployed as a Docker image instead of a zip file.

No Lambda layers here — container images don't support them. Any dependency this function needed
would be installed directly into the image instead (see [`Dockerfile`](Dockerfile)).

## Prerequisites

- Docker
- AWS CLI with credentials configured
- Terraform >= 1.14

## What it does

- Builds [`src/hello_world.py`](src/hello_world.py) into a Docker image on top of
  `public.ecr.aws/lambda/python:3.13`, AWS's base image, which already includes the Lambda
  Runtime Interface Client (RIC) — the process that polls Lambda's Runtime API for invocations and
  calls the handler named in `CMD`
- Always builds for `linux/amd64` explicitly, regardless of your host machine's architecture — on
  Apple Silicon, Docker defaults to `arm64`, which would silently mismatch the function's declared
  `x86_64` architecture in `main.tf`
- Creates an ECR repository to hold the built image
- Creates an IAM role, the basic execution policy, and a log group, as in
  [`hello_lambda/`](../hello_lambda/)
- Deploys a Lambda function with `package_type = "Image"`, pointed at `:latest` in that repository

## The chicken-and-egg problem

`aws_lambda_function` needs an image to already exist in ECR before it can be created, but the ECR
repository is itself a Terraform resource. Solve it with a two-step apply:

```bash
# 1. Create only the ECR repository
terraform apply -target=aws_ecr_repository.hello_container

# 2. Build and push an image to it
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$(terraform output -raw ecr_repository_url | cut -d/ -f1)"
docker build --platform linux/amd64 -t hello_container .
docker tag hello_container:latest "$(terraform output -raw ecr_repository_url):latest"
docker push "$(terraform output -raw ecr_repository_url):latest"

# 3. Now the image exists, so the full apply can create the function
terraform apply
```

`-target` is only needed for this first-time bootstrap. Once the repository and an image both
exist, future changes just use plain `terraform apply`.

## Testing the image locally, before pushing

AWS's base image includes a local test endpoint (the Runtime Interface Emulator) on port 8080
inside the container:

```bash
docker build --platform linux/amd64 -t hello_container .
docker run -p 9000:8080 hello_container
```

In another terminal:

```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"name": "Glen"}'
```

Response:

```json
{"statusCode": 200, "body": "Hello, Glen!", "event": {"name": "Glen"}}
```

## Invoking the deployed function

`terraform output invoke_command` prints the exact command. It looks like:

```bash
aws lambda invoke \
  --function-name hello_container \
  --region us-west-2 \
  --cli-binary-format raw-in-base64-out \
  --payload '{"name": "Glen"}' \
  /dev/stdout
```

Tail the logs with:

```bash
aws logs tail /aws/lambda/hello_container --follow --region us-west-2
```

## Redeploying after an edit

Editing `src/hello_world.py` requires a new image, not just a new `terraform apply` — Terraform
only tracks the `:latest` tag reference, not the image's contents, so it won't notice a
rebuilt-and-repushed `:latest` on its own:

```bash
docker build --platform linux/amd64 -t hello_container .
docker tag hello_container:latest "$(terraform output -raw ecr_repository_url):latest"
docker push "$(terraform output -raw ecr_repository_url):latest"
```

Lambda picks up the new image on the next invoke after the push — no `terraform apply` needed for
a same-tag update. To force Terraform to actually notice and record the new image (e.g. so
`terraform plan` isn't silently out of sync with what's deployed), pin `image_uri` to a specific
digest instead of `:latest` and update it deliberately.

## Cleaning up

```bash
terraform destroy
```

`force_delete = true` on the ECR repository means this also removes any images still pushed to it.

## Outputs

| Output               | Description                                                   |
|-----------------------|----------------------------------------------------------------|
| `function_name`       | Name of the deployed Lambda function                          |
| `ecr_repository_url`  | Push images here before applying/updating the function        |
| `log_group`           | CloudWatch log group holding this function's logs             |
| `invoke_command`      | Ready-to-run command that invokes it and prints the response  |
