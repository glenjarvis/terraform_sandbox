# Bootstrap AWS Backend

## Why this is a separate directory

If you're new to Terraform, you might ask: "This is Infrastructure as Code — shouldn't *all* the infrastructure be in one place?"

I asked the same question when I started, back in 2018. The answer is: yes, almost everything should be. But the S3 bucket and DynamoDB table that *Terraform itself* depends on are a special case.

These two resources are the foundation that every other Terraform operation in this project relies on:

- **S3 bucket** — stores Terraform state for all other modules
- **DynamoDB table** — provides locking to prevent two deploys from corrupting state simultaneously

If these resources lived alongside the rest of the infrastructure, a `terraform destroy` on a staging environment could delete the very bucket and lock table that Terraform is using to coordinate that command. That's a chicken-and-egg problem - and a dangerous one.

So this directory is intentionally isolated. You run it once, take the output, and largely forget about it.

---

## Set-up

```bash
terraform init
terraform apply
```

After `apply` completes, Terraform will print two outputs.

**1. `project_s3_configuration`** — the most important one. Copy this `backend "s3"` snippet into the `terraform` block of the main project (not this directory):

```hcl
backend "s3" {
    bucket         = "<your-bucket>"
    key            = "global/k8s/terraform.tfstate"
    region         = "<your-region>"
    dynamodb_table = "terraform-lock"
    encrypt        = true
}
```

**2. `bootstrap_s3_save_state`** — an `aws s3 cp` command to back up the bootstrap state into the S3 bucket you just created:

```bash
aws s3 cp terraform.tfstate s3://<bucket>/global/bootstrap/
```

This backup is optional, but recommended. If you lose the local `terraform.tfstate` file, this is how you recover it.

> The `terraform.tfstate` file is intentionally excluded from version control - it can contain sensitive data.

---

## Cost

Because Terraform state files are small, the cost of this S3 bucket and DynamoDB table is negligible. In most cases it will be free or a few pennies per month.

---

## Tear-down

### Simple approach

The bootstrap creates exactly two AWS resources:

- An S3 bucket ending in `-terraform-state`
- A DynamoDB table named `terraform-lock`

If you've already destroyed everything in the main project, you can delete these two resources by hand in the AWS Console or CLI and you're done.

### For the purist

If you prefer to tear down via `terraform destroy`, there are three safeguards to work through — each intentional:

1. **AWS requires a bucket to be empty before deletion** — including all previous versions
2. **This bucket has versioning enabled** — deleting objects leaves behind delete markers and old versions that must also be removed
3. **`prevent_destroy = true`** is set on both resources to prevent accidental deletion

Work through them in order.

#### Step 1 — Recover your state file (if needed)

If you no longer have the local `terraform.tfstate` file, copy it back from the S3 backup:

```bash
aws s3 cp s3://<bucket>/global/bootstrap/terraform.tfstate .
```

You must use a local state file here - you cannot use the S3 backend when you're about to delete the S3 bucket itself.

#### Step 2 — Empty the versioned bucket

First, delete all object versions:

```bash
aws s3api delete-objects \
  --bucket BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
    --bucket BUCKET_NAME \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --output json)"
```

Then delete all delete markers:

```bash
aws s3api delete-objects \
  --bucket BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
    --bucket BUCKET_NAME \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json)"
```

#### Step 3 — Remove `prevent_destroy`

In `bootstrap.tf`, remove the following block from both the `aws_s3_bucket` and `aws_dynamodb_table` resources:

```hcl
lifecycle {
  prevent_destroy = true
}
```

#### Step 4 — Destroy

```bash
terraform destroy
```

When complete, the state file will be reduced to an empty shell:

```json
{
  "version": 4,
  "terraform_version": "1.x.x",
  "serial": 30,
  "lineage": "...",
  "outputs": {},
  "resources": [],
  "check_results": null
}
```
