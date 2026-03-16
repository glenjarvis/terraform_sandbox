# ---------------------------------------------------------------------------
# IAM Role: GitHub Actions OIDC
#
# This role has no credentials of its own. It can only be accessed by
# calling STS AssumeRoleWithWebIdentity with a valid GitHub JWT.
#
# Two policies are attached to every IAM role:
#   1. Trust policy  — WHO is allowed to assume this role
#   2. Permission policy — WHAT the role can do once assumed
#
# This file defines both.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name               = "github-oidc-demo-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

resource "aws_iam_role_policy_attachment" "github_actions_permissions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_permissions.arn
}

# ---------------------------------------------------------------------------
# Trust Policy
#
# Read this as a sentence:
#   "Allow the registered GitHub OIDC provider to call AssumeRoleWithWebIdentity
#    on this role, but ONLY if the JWT's audience is sts.amazonaws.com AND
#    the subject matches this exact repo on this exact branch."
#
# The two StringEquals conditions map directly to JWT claims:
#   :aud  → the `aud` claim in the JWT GitHub mints
#   :sub  → the `sub` claim, which GitHub sets to the repo:branch that triggered the run
#
# If either condition fails, STS rejects the request before issuing credentials.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # The Federated principal references the OIDC provider we registered
    # in oidc_provider.tf. This is how the two files connect.
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # This is the guard that ensures only YOUR repo can assume this role.
    # A valid GitHub JWT from any other repo will be rejected here.
    #
    # The value must exactly match what GitHub puts in the `sub` claim.
    # For a push to main in this repo, GitHub will send:
    #   repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main"]
    }
  }
}


# ---------------------------------------------------------------------------
# Permission Policy
#
# This controls WHAT the role can do once assumed — separate from who can
# assume it. For this demo, we grant the minimum needed to verify the
# mechanism works: nothing at all.
#
# aws sts get-caller-identity is the one AWS API call that requires no
# explicit IAM permission — it is always allowed for any authenticated
# identity. So an empty permission policy is sufficient for our demo.
#
# In a real use case (deploying to S3, updating Lambda, etc.), you would
# add those specific permissions here.
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "github_actions_permissions" {
  name        = "github-oidc-demo-permissions"
  description = "Permissions for GitHub Actions OIDC demo role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Placeholder: no real permissions needed for get-caller-identity.
        # This block intentionally grants nothing.
        # Replace with actual permissions when you have a real deployment target.
        Effect   = "Deny"
        Action   = "aws:*"
        Resource = "*"
      }
    ]
  })
}



# ---------------------------------------------------------------------------
# Output: Role ARN
#
# This is the value that goes into the GitHub Actions workflow:
#   role-to-assume: <this value>
#
# After terraform apply, run: terraform output role_arn
# ---------------------------------------------------------------------------
output "role_arn" {
  description = "Paste this into .github/workflows/aws_oidc_demo.yml as role-to-assume"
  value       = aws_iam_role.github_actions.arn
}
