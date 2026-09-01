# Hello World Lambda Example

The smallest useful Lambda in Terraform: a Python function you deploy and call from the CLI.
No API Gateway, no function URL, no VPC — just the function, the role it runs as, and its logs.

## What it does

- Zips [`src/`](src/) at plan time via the `archive` provider, so there is no manual packaging step
- Creates an IAM role that only the Lambda service can assume
- Grants it `AWSLambdaBasicExecutionRole` — permission to write its own CloudWatch logs, nothing more
- Declares the log group explicitly, with 7-day retention, so `destroy` removes the logs too
- Deploys a `python3.13` function whose handler echoes back the invoke payload

Uses local state — no bootstrap S3 backend needed.

## Prerequisites

- AWS CLI with credentials configured
- Terraform >= 1.14

## Setup

```bash
terraform init
terraform apply
```

## Invoking it

`terraform output invoke_command` prints the exact command. It looks like:

```bash
aws lambda invoke \
  --function-name hello_world \
  --region us-west-2 \
  --cli-binary-format raw-in-base64-out \
  --payload '{"name": "Glen"}' \
  /dev/stdout
```

The response body is `Hello, Glen!`, with the payload echoed under `event`. Omit `--payload`
(and the `--cli-binary-format` flag it needs) to get `Hello, world!` instead.

Tail the logs with:

```bash
aws logs tail /aws/lambda/hello_world --follow --region us-west-2
```

## Redeploying after an edit

`source_code_hash` is derived from the zip, so editing `src/hello_world.py` and re-running
`terraform apply` is enough — Terraform notices the hash changed and updates the function.

## Cleaning up

```bash
terraform destroy
```

## Outputs

| Output           | Description                                          |
|------------------|------------------------------------------------------|
| `function_name`  | Name of the deployed Lambda function                 |
| `function_arn`   | ARN of the deployed Lambda function                  |
| `log_group`      | CloudWatch log group holding this function's logs    |
| `invoke_command` | Ready-to-run command that invokes it and prints the response |
