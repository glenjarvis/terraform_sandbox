# Part-Progressive OIDC + GitHub + AWS Learning Curriculum

## Goal

Understand how GitHub Actions can authenticate to AWS via OIDC (OpenID Connect), enabling CI/CD
workflows to assume IAM roles without storing hard-coded AWS credentials.

**Teaching approach:** Each Part is a self-contained concept that later parts depend on. We start
with the most fundamental skill and add one layer at a time. Each part follows:
concept explanation → how it connects to prior parts → hands-on Terraform (where applicable).

---

## Part A — What Is OIDC? (The Protocol Itself)
**Concept only. No code.**

- OAuth 2.0 is for authorization. OIDC adds *identity* on top of it.
- Core artifact: the **JWT** (JSON Web Token) — a signed, base64-encoded claim bundle.
- Structure of a JWT: header / payload (claims) / signature.
- Key claim fields GitHub will use: `iss`, `sub`, `aud`, `exp`.
- How a *Relying Party* (AWS) trusts a JWT: it fetches the IdP's public key and verifies the signature.

**Why this is Part A:** Every later part builds on "a JWT proves identity."

---

## Part B — GitHub as an OIDC Identity Provider
**Concept only. No code.**

- GitHub Actions generates a signed JWT for *each workflow run*.
- JWT is obtained via the `ACTIONS_ID_TOKEN_REQUEST_URL` / `ACTIONS_ID_TOKEN_REQUEST_TOKEN` env vars.
- The `sub` claim encodes exactly *which* repo, branch, environment, or PR triggered the run.
  Example: `repo:myorg/myrepo:ref:refs/heads/main`
- GitHub publishes its public keys at:
  `https://token.actions.githubusercontent.com/.well-known/jwks`
- The **thumbprint** is the SHA-1 fingerprint of the TLS certificate at that endpoint — AWS uses
  it to verify it's really talking to GitHub.

**Why this is Part B:** You need to know *what GitHub produces* before you can teach AWS to trust it.

---

## Part C — AWS STS and AssumeRoleWithWebIdentity
**Concept only. No code yet.**

- **STS** (Security Token Service): AWS's service for issuing *temporary* credentials.
- Key API call: `AssumeRoleWithWebIdentity(RoleArn, WebIdentityToken)`.
  - Input: an OIDC JWT from an external IdP.
  - Output: temporary `AccessKeyId` + `SecretAccessKey` + `SessionToken` (valid 1–12 hours).
- IAM **roles** vs IAM **users**: roles have no long-lived credentials; they are *assumed*.
- The **trust policy** (on the role) answers: *who is allowed to call AssumeRole?*
  - It can restrict by IdP, by `aud` claim, and by `sub` claim.

**Why this is Part C:** This is the bridge mechanism. Parts D–F are all about configuring it correctly.

---

## Part D — Wiring AWS to Trust GitHub's OIDC Tokens
**Concept + first Terraform.**

- AWS needs to know GitHub's OIDC endpoint exists and is trustworthy → the
  `aws_iam_openid_connect_provider` resource.
- The `thumbprint_list` value: fetched dynamically via `data "tls_certificate"`.
- The trust policy on the IAM role:
  - Principal: `Federated: <oidc-provider-arn>`
  - Action: `sts:AssumeRoleWithWebIdentity`
  - Condition: `token.actions.githubusercontent.com:aud = sts.amazonaws.com`
  - Condition: `token.actions.githubusercontent.com:sub` scoped to your repo

**Files to create:**
- `terraform/oidc_provider.tf` — OIDC provider + TLS data source
- `terraform/iam_role.tf` — IAM role with trust policy + minimal permission policy
- `terraform/variables.tf` — `github_org`, `github_repo` variables
- `terraform/outputs.tf` — role ARN output

---

## Part E — The GitHub Actions Workflow Side
**Concept + YAML.**

- The workflow must declare `permissions: id-token: write` — without this GitHub won't issue a JWT.
- The `aws-actions/configure-aws-credentials` action calls `AssumeRoleWithWebIdentity` under the hood.
- After it runs, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` are set in the env.
- The credentials are scoped only to what the IAM role allows, and expire automatically.

**Files to create:**
- `.github/workflows/aws_oidc_demo.yml` — minimal workflow that authenticates and runs `aws sts get-caller-identity`

---

## Part F — Verify It Works End-to-End
**Hands-on validation.**

1. `terraform init && terraform apply` in the sandbox repo.
2. Push the workflow file and trigger it.
3. Observe the `aws sts get-caller-identity` output in GitHub Actions — confirms the assumed role ARN.

---

## Part G — Security Hardening (Condition Scoping)
**Concept + Terraform refinement.**

- Why `StringLike` vs `StringEquals` matters for the `sub` condition.
- Scoping trust to a specific branch: `repo:org/repo:ref:refs/heads/main`
- Scoping trust to a GitHub Environment: `repo:org/repo:environment:production`
- Principle of least privilege: what permissions should the role actually have?

---

## Files Overview

| File | Purpose |
|---|---|
| `README.md` | Project overview |
| `terraform/oidc_provider.tf` | `aws_iam_openid_connect_provider` + `data "tls_certificate"` |
| `terraform/iam_role.tf` | IAM role, trust policy, permission attachment |
| `terraform/variables.tf` | `github_org`, `github_repo`, `aws_region` |
| `terraform/outputs.tf` | `role_arn` |
| `.github/workflows/aws_oidc_demo.yml` | Demo workflow using OIDC auth |

---

## Verification

End-to-end test:
1. `terraform apply` produces a role ARN with no errors.
2. GitHub Actions workflow runs successfully.
3. `aws sts get-caller-identity` output in the workflow shows the assumed role ARN (not a user ARN).
4. Confirm temporary credentials expire (`AWS_SESSION_TOKEN` is set in the workflow env).
