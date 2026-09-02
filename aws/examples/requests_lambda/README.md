# Requests Lambda Example

A Lambda function that uses the `requests` library without bundling it — the library comes from
a layer published separately by [`requests_layer/`](../requests_layer/).

The function fetches `https://checkip.amazonaws.com` and returns the public IP that AWS sees it
calling from.

## Prerequisites

- The `requests` layer must already be published in `us-west-2` — see
  [`requests_layer/`](../requests_layer/)
- AWS CLI with credentials configured
- Terraform >= 1.14

This example consumes a layer it does not own. If no layer named `requests` exists in the
region, `terraform plan` fails at the data source lookup. That is the intended behavior — it is what depending on shared infrastructure looks like.

## What it does

- Packages [`src/`](src/) — one file, `check_ip.py`, and nothing else
- Looks the layer up by name with `data "aws_lambda_layer_version"`, taking the current version
- Attaches that version ARN to the function via `layers`
- Creates an IAM role, the basic execution policy, and a log group, as in
  [`hello_lambda/`](../hello_lambda/)

## Setup

```bash
terraform init
terraform apply
```

## Invoking it

```bash
aws lambda invoke \
  --function-name check_ip \
  --region us-west-2 \
  /dev/stdout
```

Response:

```json
{
  "statusCode": 200,
  "body": "54.190.0.0",
  "requests_version": "2.34.2",
  "requests_module": "/opt/python/requests/__init__.py"
}
```

`requests_module` is the point of the whole example. `/opt/python/` is the layer, mounted at
runtime. If it ever reads `/var/task/requests/...` instead, the dependency leaked into the
deployment package and the layer is doing nothing.

`requests_version` should match the pin in
[`../requests_layer/requirements.txt`](../requests_layer/requirements.txt) — that file is the
contract between the two examples.

Tail the logs with:

```bash
aws logs tail /aws/lambda/check_ip --follow --region us-west-2
```

## Looking up by name, not by ARN

Every publish creates a new, immutable layer version; AWS never mutates an existing one. A
hardcoded `...:layer:requests:1` therefore goes stale the moment the layer is rebuilt.

The data source resolves the current version at plan time, so republishing the layer and
re-running `apply` here moves the function forward. Terraform shows the ARN changing from `:1`
to `:2` in the plan — the version bump is visible, not silent.

If you need a function pinned to a known-good version, hardcode the version ARN deliberately.
That is a real choice, not an oversight.

## Cleaning up

```bash
terraform destroy
```

Do this before destroying the layer — a layer version cannot be deleted while a function still
references it.

## Outputs

| Output              | Description                                                |
|---------------------|------------------------------------------------------------|
| `function_name`     | Name of the deployed Lambda function                       |
| `layer_version_arn` | The layer version this function resolved and attached to   |
| `log_group`         | CloudWatch log group holding this function's logs          |
| `invoke_command`    | Ready-to-run command that invokes it and prints the response |
