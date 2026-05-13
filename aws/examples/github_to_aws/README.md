# GitHub to AWS Example

Demonstrates how GitHub Actions can authenticate to AWS via OIDC (OpenID Connect) — no
long-lived credentials required. A GitHub Actions workflow assumes an IAM role using a
short-lived JWT that GitHub mints per workflow run.

## NOT TESTED

This directory has a series of notes so that I can understand how OIDC works in
general, and then specifically, with GITHUB as an OIDC provider.

These notes have not been put together and tested.

## What it does

- Registers GitHub as a trusted OIDC Identity Provider in your AWS account
- Creates an IAM role with a trust policy scoped to this specific repository and branch
- The accompanying workflow (`.github/workflows/aws_oidc_demo.yml`) assumes the role and
  calls `aws sts get-caller-identity` to confirm the exchange worked

## How it works

```
GitHub runner -> requests JWT from GitHub's token service
              -> calls AWS STS AssumeRoleWithWebIdentity(RoleArn, JWT)
AWS STS       -> verifies JWT signature using GitHub's public keys
              -> checks aud and sub claims against the trust policy
              -> issues temporary credentials (expire automatically)
```

See [`docs/oidc_github_aws_notes.md`](../../docs/oidc_github_aws_notes.md) for a full
conceptual walkthrough.

## Prerequisites

- AWS CLI with credentials configured
- Bootstrap S3 backend must be set up first — see [`bootstrap/`](../../bootstrap/README.md)

## Setup

```bash
terraform init
terraform apply
```

After apply, note the `role_arn` output and follow the instructions in
[`.github/workflows/README.md`](../../.github/workflows/README.md) to configure the
GitHub Actions workflow.

## Outputs

| Output     | Description                                             |
|------------|---------------------------------------------------------|
| `role_arn` | ARN of the IAM role — paste into the GitHub Actions workflow |
