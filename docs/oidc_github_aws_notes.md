# OIDC, GitHub Actions, and AWS: A Ground-Up Reference

This document captures the conceptual and practical knowledge needed to understand how GitHub
Actions can authenticate to AWS via OIDC — without storing any hard-coded credentials.

The progression follows a part-progressive structure: each concept is a foundation for the next.

---

## Table of Contents

1. [The One-Sentence Version](#the-one-sentence-version)
2. [Part A: OIDC and JWTs](#part-a-oidc-and-jwts)
3. [Part B: GitHub as an OIDC Identity Provider](#part-b-github-as-an-oidc-identity-provider)
4. [Part C: AWS STS and the Bridge Mechanism](#part-c-aws-sts-and-the-bridge-mechanism)
5. [Part D: The Terraform Implementation](#part-d-the-terraform-implementation)
6. [Part E: The GitHub Actions Workflow](#part-e-the-github-actions-workflow)
7. [The Complete End-to-End Flow](#the-complete-end-to-end-flow)
8. [Security Considerations](#security-considerations)
9. [Debugging a Failing Scenario](#debugging-a-failing-scenario)

---

## The One-Sentence Version

GitHub mints a signed badge per workflow run. AWS reads that badge and decides whether to issue
temporary credentials. No stored secrets anywhere.

---

## Part A: OIDC and JWTs

### What OIDC is

OAuth 2.0 handles *authorization* (can you do this?). OIDC (OpenID Connect) adds *identity* on
top of it (who are you?). OIDC is the protocol. The JWT is its core artifact.

### What a JWT is

A JWT (JSON Web Token) is three base64-encoded chunks joined by dots:

```
header.payload.signature
```

The encoding is not encryption — you can paste any JWT into jwt.io and read it. The security
comes entirely from the **signature**, not the encoding.

### The payload: claims

The payload is a JSON object called **claims**. For a GitHub Actions JWT it looks like:

```json
{
  "iss": "https://token.actions.githubusercontent.com",
  "aud": "sts.amazonaws.com",
  "sub": "repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main",
  "exp": 1710000000
}
```

The four claims that matter for GitHub → AWS:

| Claim | Meaning | AWS uses it to... |
|---|---|---|
| `iss` | Issuer — who created this JWT | Confirm it came from GitHub specifically |
| `aud` | Audience — who this JWT is *for* | Confirm it was minted for AWS STS |
| `sub` | Subject — what triggered the run | Match against your trust policy conditions |
| `exp` | Expiry timestamp | Automatically reject expired tokens |

### The two-layer defense

**Layer 1: Signature verification (the hard guarantee)**

GitHub signs the JWT with a private key only GitHub holds. AWS verifies the signature using
GitHub's public key. This is what prevents anyone from forging a JWT claiming to be GitHub.
You cannot fake the signature without GitHub's private key.

**Layer 2: Claim validation (scoping)**

Once AWS knows the token is genuinely from GitHub, it checks the claims against your IAM trust
policy conditions:

- `iss` — confirms it's GitHub, not some other OIDC provider
- `aud` — confirms it was requested for AWS (GitHub lets workflows request tokens for different audiences)
- `sub` — confirms it's *your* repo/branch, not someone else's

Think of it like a passport:
- The **signature** is the hologram — proves the passport is genuine.
- The **claims** are the fields inside — border control reads them to decide whether to let you through.

A forged passport fails at the hologram. A real passport from the wrong country fails at the fields.
AWS requires both checks to pass.

---

## Part B: GitHub as an OIDC Identity Provider

### GitHub's role

GitHub is the **Identity Provider (IdP)**. It vouches not for a human, but for a *workflow run* —
the specific context of that run: which repo, which branch, which triggering event.

### How the JWT gets created

When a GitHub Actions workflow run starts, GitHub mints a fresh JWT *for that run*. Two things
must be true:

1. The workflow must declare `permissions: id-token: write`. Without this, GitHub refuses to mint
   the token. It is opt-in by design.
2. The `aws-actions/configure-aws-credentials` action handles the token request automatically.

### What GitHub puts in `sub`

The `sub` claim is how GitHub describes exactly what triggered the run:

| Trigger | `sub` value |
|---|---|
| Push to a branch | `repo:org/repo:ref:refs/heads/main` |
| Pull request | `repo:org/repo:pull_request` |
| A GitHub Environment | `repo:org/repo:environment:production` |
| A tag | `repo:org/repo:ref:refs/tags/v1.0.0` |

GitHub sets this honestly and the workflow cannot override it. A workflow running on `main`
cannot claim it's running in `environment:production`.

### The JWKS endpoint

GitHub publishes its public signing keys at:
```
https://token.actions.githubusercontent.com/.well-known/jwks
```

AWS fetches from this URL to verify JWT signatures. The OIDC discovery document is at:
```
https://token.actions.githubusercontent.com/.well-known/openid-configuration
```

### The thumbprint — and what it actually is

The thumbprint that appears in Terraform:

```hcl
thumbprint_list = [
  data.tls_certificate.github.certificates[0].sha1_fingerprint
]
```

This is **not** the certificate for `token.actions.githubusercontent.com` itself. It is the
SHA-1 fingerprint of the **root CA certificate** that signed that endpoint's TLS certificate.

When Terraform runs `data "tls_certificate"`, it connects to the URL, walks the certificate
chain, and extracts the root CA's fingerprint. AWS uses this to verify it's talking to the
legitimate JWKS endpoint before trusting the public keys it fetches there.

**Important nuance:** AWS now pre-trusts the CA GitHub uses (DigiCert), so for GitHub the
thumbprint is largely ceremonial. But for a custom OIDC provider using a private or internal CA,
the thumbprint is essential. The Terraform pattern of fetching it dynamically is the right habit
regardless — it's correct in all cases and handles CA rotation automatically.

### Any service can be an OIDC provider

This is the key insight that unlocks the whole pattern:

> If JoesWidgets.com published its own JWKS at
> `https://security.joeswidgets.com/.well-known/jwks` and its own openid-configuration,
> and signed JWTs with the corresponding private key, AWS would trust JoesWidgets-issued
> JWTs just as it trusts GitHub's — as long as you registered JoesWidgets as an IAM OIDC
> Identity Provider.

Real examples that use this exact pattern:
- **GitLab** (self-hosted or gitlab.com)
- **Kubernetes** — pods can assume IAM roles without credentials (EKS pod identity)
- **HashiCorp Vault**
- **Azure AD / Entra ID** — lets Azure identities assume AWS roles (uses SAML or OIDC)

AWS won't automatically trust any OIDC provider. You must explicitly register it first — that
registration step is the gate.

---

## Part C: AWS STS and the Bridge Mechanism

### What STS is

STS (Security Token Service) issues *temporary* credentials. Temporary means they expire —
minutes to hours — and leave no permanent access behind. This is the same service behind
`aws sts assume-role`, instance profiles, and Lambda execution roles. OIDC is just one of
several ways to convince STS to issue credentials.

### The specific API call

When `configure-aws-credentials` runs, it calls:

```
AssumeRoleWithWebIdentity(
  RoleArn          = "arn:aws:iam::123456789012:role/github-oidc-demo-role",
  WebIdentityToken = <the JWT GitHub minted>
)
```

STS then:
1. Decodes the JWT
2. Checks `iss` — is this a registered OIDC provider in this account?
3. Fetches GitHub's public keys from the JWKS endpoint (verifying the TLS thumbprint)
4. Verifies the JWT signature
5. Checks `aud` matches `sts.amazonaws.com`
6. Checks `sub` against the trust policy conditions on the role
7. If everything passes — issues temporary credentials

### Temporary credentials: three required parts

STS returns three values:

| Value | Starts with | Purpose |
|---|---|---|
| `AccessKeyId` | `ASIA...` | Like a username (permanent keys start with `AKIA...`) |
| `SecretAccessKey` | (random) | Signs API requests via SigV4 |
| `SessionToken` | (opaque blob) | Carries expiry and session metadata, required on every call |

**Why all three are required:** The `ASIA` prefix signals to every AWS service that a
`SessionToken` is mandatory. Without it, the call is rejected outright. The SessionToken is
cryptographically signed by AWS internally and encodes the expiry — no database lookup needed
to check it. This means there is nothing to clean up when credentials expire; they simply stop
being accepted.

**Security consequence:** If someone steals only the `AccessKeyId` and `SecretAccessKey` from
a set of temporary credentials, they still can't use them — the `SessionToken` is missing and
the call fails.

### IAM roles vs IAM users

| | IAM User | IAM Role |
|---|---|---|
| Has permanent credentials | Yes | No |
| Can be assumed temporarily | No | Yes |
| What OIDC uses | Never | Always |

An IAM role has no credentials of its own. It is a set of permissions that can be *assumed*
temporarily via STS.

### The two questions every role answers

Every IAM role has two separate policies:

| Policy | Question | Where it lives |
|---|---|---|
| **Trust policy** | Who is allowed to call AssumeRole on this role? | Inside `aws_iam_role` as `assume_role_policy` |
| **Permission policy** | What can the role do once assumed? | Separate `aws_iam_policy` + `aws_iam_role_policy_attachment` |

### Federated vs SSO vs SAML

| Term | What it is |
|---|---|
| **Federation** | The *concept* — trusting an external identity system instead of managing identities yourself |
| **SAML** | A specific *protocol* for federation — XML-based, enterprise-focused, predates OIDC (2002) |
| **OIDC** | A specific *protocol* for federation — JWT-based, modern (2014) |
| **SSO** | A *user experience* outcome — log in once, access many systems |

`Federated` in an IAM trust policy means "this identity comes from an external provider." It
works for both SAML and OIDC:

```json
// OIDC provider
"Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"

// SAML provider (e.g., Azure AD)
"Federated": "arn:aws:iam::123456789012:saml-provider/AzureAD"
```

OIDC is the modern successor to SAML. For anything new being built today, OIDC is the default.
SAML remains in enterprises due to inertia — it's deeply embedded in legacy infrastructure.
The practical split in large enterprises: **SAML for humans, OIDC for machines.**

---

## Part D: The Terraform Implementation

### Three files, one chain

```
oidc_provider.tf          iam_role.tf
─────────────────         ──────────────────────────────────────
aws_iam_openid_           aws_iam_role
connect_provider    ←──   (trust policy references provider ARN)
                          aws_iam_role_policy_attachment
                          aws_iam_policy ──────────────────────┘
```

### `oidc_provider.tf` — registering GitHub

```hcl
# Fetches the root CA certificate fingerprint from GitHub's TLS endpoint.
# Run at terraform apply time from wherever you run Terraform.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Registers GitHub as a trusted OIDC Identity Provider in this AWS account.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]   # the required `aud` claim value
  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}
```

This resource gets an ARN like:
```
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
```

No region in the ARN — IAM is a global service.

**Without this resource:** AWS has no knowledge that GitHub exists as an identity provider.
No JWT from GitHub could ever be verified or trusted, regardless of how the IAM role is
configured.

### `iam_role.tf` — the role and its policies

The trust policy (who can assume the role):

```hcl
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The guard that makes this role yours specifically.
    # Any valid GitHub JWT from any other repo is rejected here.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main"]
    }
  }
}
```

The role, attachment, and permission policy:

```hcl
resource "aws_iam_role" "github_actions" {
  name               = "github-oidc-demo-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

resource "aws_iam_role_policy_attachment" "github_actions_permissions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_permissions.arn
}

resource "aws_iam_policy" "github_actions_permissions" {
  name   = "github-oidc-demo-permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Deny", Action = "aws:*", Resource = "*" }]
  })
}
```

The permission policy is `Deny *` for the demo because `aws sts get-caller-identity` requires
no explicit IAM permission — it works for any authenticated identity. Replace with real
permissions when you have an actual deployment target.

### Why three separate resources for the permission side

| Option | Resource type | Reusable across roles? |
|---|---|---|
| `inline_policy` block in `aws_iam_role` | Inline | No |
| `aws_iam_role_policy` referencing the role | Inline | No |
| `aws_iam_policy` + `aws_iam_role_policy_attachment` | Managed | Yes |

Managed policies (option 3) can be attached to multiple roles without duplication.

### `main.tf` — providers and backend

```hcl
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "com-glenjarvis-demo-terraform-state"
    key            = "global/github_oidc/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

The `tls` provider is separate from `aws` because TLS is not an AWS concept — it's a general
internet protocol. The `tls` provider gives Terraform the ability to inspect TLS certificates
at any URL. Declaring it in `required_providers` pins the version for reproducibility; without
the declaration, Terraform would still find and use it implicitly, but at whatever version
happens to be latest.

---

## Part E: The GitHub Actions Workflow

```yaml
name: AWS OIDC Demo

on:
  push:
    branches: [main]
  workflow_dispatch:

# Without id-token: write, GitHub refuses to mint an OIDC JWT for this workflow.
# It is intentionally opt-in — workflows that don't need AWS access get no token.
permissions:
  id-token: write   # allows GitHub to mint an OIDC JWT for this run
  contents: read    # allows checkout

jobs:
  verify-aws-identity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # This action does the full OIDC exchange:
      #   1. Requests the JWT from GitHub (via ACTIONS_ID_TOKEN_REQUEST_URL)
      #   2. Calls AWS STS AssumeRoleWithWebIdentity with that JWT
      #   3. Exports AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-oidc-demo-role
          aws-region: us-west-2

      # If OIDC worked, the output shows the assumed role ARN — not a user ARN.
      - name: Verify assumed identity
        run: aws sts get-caller-identity
```

### What `permissions: id-token: write` does

GitHub's internal permissions system controls what a workflow can do *within GitHub*. The
`id-token: write` permission specifically controls whether GitHub's infrastructure will mint an
OIDC JWT for this workflow run. It has nothing to do with AWS — it's a GitHub-side gate.

`contents: read` is a separate permission controlling access to the repository's files. Not
related to OIDC, but required for `actions/checkout` to work.

### What `configure-aws-credentials` does step by step

1. Calls `ACTIONS_ID_TOKEN_REQUEST_URL` with the `ACTIONS_ID_TOKEN_REQUEST_TOKEN` to request
   a JWT from GitHub's internal token service
2. Calls `AWS STS AssumeRoleWithWebIdentity(RoleArn, WebIdentityToken=<jwt>)`
3. Receives `AccessKeyId`, `SecretAccessKey`, `SessionToken` from STS
4. Exports all three as environment variables for subsequent workflow steps

**Key point:** AWS never calls back to GitHub at runtime. It verifies the JWT signature locally
using the public key it has from the OIDC provider registration. GitHub's role ends the moment
it signs the JWT.

---

## The Complete End-to-End Flow

```
terraform apply time:
  Your machine → fetches TLS cert from token.actions.githubusercontent.com
               → extracts root CA thumbprint
               → registers GitHub OIDC provider in AWS (with thumbprint)
               → creates IAM role with trust policy + permission policy

Workflow run time:
  GitHub runner → requests JWT from GitHub's internal token service
               → receives JWT signed by GitHub's private key
               → calls AWS STS AssumeRoleWithWebIdentity(RoleArn, JWT)

  AWS STS       → sees ASIA... prefix, knows this is a web identity request
               → checks: is the issuer (iss) a registered OIDC provider?
               → fetches GitHub's public key from JWKS (verifying TLS thumbprint)
               → verifies JWT signature locally
               → checks aud == "sts.amazonaws.com"
               → checks sub == "repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main"
               → issues temporary credentials (AccessKeyId + SecretAccessKey + SessionToken)

  GitHub runner → exports credentials as env vars
               → runs aws sts get-caller-identity
               → response shows assumed role ARN (not a user ARN) ✓
```

---

## Security Considerations

### The most dangerous misconfiguration: missing `sub` condition

If you register the GitHub OIDC provider but create the IAM role trust policy **without a
`sub` condition**, any GitHub Actions workflow from any repository in the world can assume
your role. The `aud` condition alone doesn't help — `sts.amazonaws.com` is the audience for
every GitHub→AWS OIDC flow.

The `sub` condition is the only thing that makes the role yours.

### Auditing for this mistake

**AWS IAM Access Analyzer** is the most direct tool. It analyzes IAM policies and flags roles
accessible from outside your account. A GitHub OIDC role with no `sub` condition will be
flagged as publicly accessible.

Other options:
- **AWS Config rules** — custom rule that inspects trust policies continuously
- **`terraform plan` review** — the full trust policy JSON appears in plan output; catch it in code review
- **`aws iam simulate-principal-policy`** — manually test whether a foreign repo can assume the role

### `StringEquals` vs `StringLike` (Part G)

`StringEquals` requires an exact match. `StringLike` supports wildcards (`*`).

```hcl
# Exact — only main branch
"StringEquals": { "...sub": "repo:glenjarvis/oidc_github_aws_sandbox:ref:refs/heads/main" }

# Wildcard — any branch in this repo (use carefully)
"StringLike": { "...sub": "repo:glenjarvis/oidc_github_aws_sandbox:*" }
```

Scoping options:
- Specific branch: `repo:org/repo:ref:refs/heads/main`
- GitHub Environment: `repo:org/repo:environment:production`
- Specific tag: `repo:org/repo:ref:refs/tags/v1.0.0`

---

## Debugging a Failing Scenario

### See the exact JWT claims GitHub sends

Add this step *before* `configure-aws-credentials`:

```yaml
- name: Decode OIDC token claims
  run: |
    TOKEN=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r '.value')
    echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

This prints the full JWT payload — the exact `sub`, `aud`, `iss`, and `exp` values GitHub
actually sent. Compare `sub` against what you wrote in the trust policy condition.

### AWS CloudTrail

Failed `AssumeRoleWithWebIdentity` calls are logged in CloudTrail. Filter by event name
`AssumeRoleWithWebIdentity` to find the attempt and see which condition failed.

### The STS error message

When `configure-aws-credentials` fails, the error from STS usually names which condition
didn't match. Look for output like `sub claim did not match` in the workflow logs.

---

## Verification Checklist (Part F)

After `terraform apply`:

1. `terraform output role_arn` — copy the ARN, confirm it matches what's in the workflow
2. Push to `main` — triggers the workflow
3. In GitHub Actions, the `Verify assumed identity` step output should show:
   ```json
   {
     "UserId": "AROA...:GitHubActions",
     "Account": "123456789012",
     "Arn": "arn:aws:iam::123456789012:assumed-role/github-oidc-demo-role/..."
   }
   ```
   The `Arn` shows `assumed-role/github-oidc-demo-role` — not a user ARN. That is the proof
   the mechanism works.
4. Push to a feature branch — the workflow should fail at the `configure-aws-credentials` step
   because the `sub` won't match the `main`-branch-only condition.
