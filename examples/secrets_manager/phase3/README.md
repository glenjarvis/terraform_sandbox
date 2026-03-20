# Phase 3 — Consume Secrets

Demonstrates the progression from unsafe to safe patterns for consuming AWS Secrets
Manager secrets in Terraform. Each demo is a standalone `.tf.disabled` file. Enable
one at a time - and before moving to the next, run `terraform destroy` and rename
the file back to `.disabled`.

Complete Phase 1 and Phase 2 before running any demo here.

## Demo sequence

The demos tell a story - work through them in order.

### demo_01 - `sensitive = true` does not protect state

Shows that marking an output `sensitive = true` hides the value in plan output but
does **not** prevent it from being written to state. The secret appears in two places
in `.tfstate`.

**Lesson:** `sensitive` is not a security boundary - it is a display hint only.

---

### demo_02 — `data` source stores the secret in state

Reads the secret via a `data` source. The `secret_string` is written to state as
plain text.

**Lesson:** Any value passing through a `data` block ends up in `.tfstate`.

---

### demo_03 — `ephemeral` keeps the secret out of state

Reads the same secret using an `ephemeral` resource instead. Nothing is written to
state — the value exists in memory during apply only.

**Lesson:** `ephemeral` is the correct tool for reading secrets that should never
touch state.

---

### demo_04 — `ephemeral` values cannot flow into regular attributes (intentional failure)

Attempts to use the ephemeral secret value for `db_name`, `username`, and `password`
on `aws_db_instance`. Terraform rejects this at plan time - all three are regular
(non-write-only) attributes.

**Lesson:** Ephemeral values can only flow into write-only (`_wo`) attributes.

---

### demo_05 — the tempting (wrong) fix: switch back to `data`

After seeing demo_04 fail, it is tempting to replace `ephemeral` with `data`. This
creates the RDS instance successfully - but stores the secret in state twice:
once in the data source and once in the `password` attribute.

**Lesson:** Switching back to `data` to work around the ephemeral constraint defeats
the entire purpose.

---

### demo_06 — `ephemeral` + `password_wo` (correct solution)

Uses an `ephemeral` resource for the password and the write-only `password_wo`
attribute. The password is never written to state. `password_wo_version` acts as a
surrogate change trigger since Terraform cannot compare write-only values directly.

`db_name` and `username` have no write-only equivalents so they are passed as
variables and will appear in state - this is unavoidable with the current AWS
provider.

**Lesson:** `ephemeral` + `password_wo` is the right pattern. Only the password is
truly protected; other attributes require a separate risk assessment.

---

### demo_07 — `manage_master_user_password = true` (best pattern for RDS)

Delegates password management entirely to AWS. RDS generates, stores, and rotates
the password in Secrets Manager. Terraform never sees the password at all.

**Lesson:** When AWS can own the secret lifecycle, let it. This eliminates the
problem rather than managing it.

## Prerequisites

- Phase 1 applied (`demo/app/db_credentials` and `demo/app/db_password` exist)
- Phase 2 complete (both secrets populated)
- Terraform >= 1.10 (required for `ephemeral` resources and `_wo` attributes)
- AWS CLI with credentials configured

## Usage

```bash
# Enable one demo at a time, e.g.:
mv demo_01.tf.disabled demo_01.tf
terraform init
terraform apply

# Examine state after apply:
terraform state pull | jq . | less

# Disable when done:
terraform destroy
mv demo_01.tf demo_01.tf.disabled
```
