# Secrets Manager Example

Demonstrates how to use AWS Secrets Manager with Terraform across three phases —
showing both unsafe patterns and the safer alternatives that avoid writing secrets
to state or local files.

## Why three phases?

Any value written to a `resource` or `data` block ends up in `.tfstate`. This
may be a security risk. There may be users who have access to the `.tfstate`
but who do not have access to the secrets in the AWS Secrets Store.

The three-phase pattern breaks the workflow into steps where each step has a clear
boundary:

1. **Terraform creates the containers** - empty secret slots in AWS Secrets Manager.
2. **A human populates the values** - directly via the AWS CLI or
   console, never touching Terraform state.
3. **Terraform creates the consuming resources** - a progression of demos explores
   the right and wrong ways to consume secrets, arriving at the pattern where the
   value never enters Terraform state.

This means Terraform only ever sees the ARN (a pointer), never the secret value.

## Phases

| Phase | Directory |                  What it does                         |
|-------|-----------|-------------------------------------------------------|
|   1   | `phase1/` | Creates empty secret containers; outputs their ARNs   |
|   2   | `phase2/` | Manual step — populate secret values via AWS CLI      |
|   3   | `phase3/` | Creates resources that consume the secrets (e.g. RDS) |

## Teardown

Phase 3 can be built and destroyed as necessary. However, if the entire project
is being removed, phase1 also needs to be destroyed.

Phase 3 must be torn down before phase1, because phase3 resources depend on the
secrets that phase1 owns.

```bash
cd phase3 && terraform destroy
cd phase1 && terraform destroy
```

## Cost

Secrets Manager charges $0.40 per secret per month, prorated to the hour. Both
secrets in this example use `recovery_window_in_days = 0` for immediate deletion on
destroy. For a short learning exercise, the cost is fractions of a cent.
