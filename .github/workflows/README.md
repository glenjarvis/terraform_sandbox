# GitHub Actions Workflows

## aws_oidc_demo.yml

Demonstrates GitHub Actions authenticating to AWS via OIDC (OpenID Connect) — no long-lived
credentials required. Triggered manually, it assumes an IAM role and calls
`aws sts get-caller-identity` to confirm the OIDC exchange worked.

### How it works

1. GitHub mints a short-lived JWT for the workflow run (using the `id-token: write` permission)
2. The `aws-actions/configure-aws-credentials` action exchanges that JWT for temporary AWS
   credentials via `STS AssumeRoleWithWebIdentity`
3. Subsequent steps run with those credentials scoped to the assumed role

### Prerequisites

#### 1. Terraform: Create the IAM role

The IAM role and OIDC provider are created by the Terraform configuration in
`examples/github_to_aws/`. Run that first:

```bash
cd examples/github_to_aws
terraform init
terraform apply
```

Note the `role_arn` output — you'll need it in the next step.

#### 2. GitHub: Set repository secret and variable

**Secret** - go to: **Settings > Secrets and variables > Actions > Secrets tab**

| Secret           | Description                                   | Example value  |
|------------------|-----------------------------------------------|----------------|
| `AWS_ACCOUNT_ID` | AWS account ID where the IAM role was created | `123456789012` |

> **Why a secret for the account ID?** While AWS does not classify account IDs as sensitive,
> storing it as a secret keeps it out of logs and follows a conservative, security-team-friendly
> posture for a public repo.

**Variable** - go to: **Settings > Secrets and variables > Actions > Variables tab**

| Variable     | Description                           | Example value |
|--------------|---------------------------------------|---------------|
| `AWS_REGION` | AWS region where the role was created | `us-west-2`   |

#### 3. Trust policy

The IAM trust policy must allow the `sub` claim for this specific repository. The Terraform
in `examples/oidc/` sets this automatically, but if you fork this repo the trust policy must
be updated to match your repository name:

```
repo:<your-github-username>/terraform_sandbox:ref:refs/heads/main
```
