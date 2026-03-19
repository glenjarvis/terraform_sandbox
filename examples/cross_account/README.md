# Cross-Account Example

Demonstrates how a management (root) AWS account can assume a role in a member account. This
allows one to work on a different account without having a separate set of credentials.

## How it works

Two aliased AWS providers are configured:

- `management_account` — uses your current credentials (the management/root account)
- `other_account` — assumes `OrganizationAccountAccessRole` in the other account

Terraform then calls `aws sts get-caller-identity` via each provider and outputs both account IDs.

## Trust relationship prerequisite

This example relies on `OrganizationAccountAccessRole` existing in the member account with a
trust policy that allows the management account to assume it.

**If the member account was created via AWS Organizations**, this role is created automatically.
The trust policy allows any principal in the management account to assume it:

```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::<MANAGEMENT_ACCOUNT_ID>:root"
  },
  "Action": "sts:AssumeRole"
}
```

**If the member account was created manually**, you must create this role yourself in the member
account with the trust policy above.

## Usage

Supply your member account ID at apply time:

```bash
terraform init
terraform apply -var="org_member_account_id=<MEMBER_ACCOUNT_ID>"
```

Or create a `terraform.tfvars` file (gitignored):

```hcl
org_member_account_id = "123456789012"
```

## Outputs

| Output                              | Description                          |
| ----------------------------------- | ------------------------------------ |
| `account_management_id`             | Account ID of the management account |
| `account_other_id`                  | Account ID of the other account      |
