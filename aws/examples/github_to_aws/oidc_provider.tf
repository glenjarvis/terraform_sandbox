# ---------------------------------------------------------------------------
# GitHub OIDC Identity Provider Registration
#
# This tells AWS: "I trust JWTs signed by GitHub Actions."
#
# Without this resource, AWS has no knowledge that GitHub exists as an
# identity provider. No JWT from GitHub could ever be verified or trusted,
# regardless of how the IAM role is configured.
# ---------------------------------------------------------------------------

# Step 1: Fetch GitHub's TLS certificate at apply time.
#
# Terraform reaches out to this URL from wherever you run `terraform apply`
# and walks the certificate chain to find the ROOT CA certificate.
# The SHA-1 fingerprint of that root CA is what AWS will use to verify
# that the JWKS endpoint it fetches public keys from is genuinely GitHub.
#
# Note: AWS now pre-trusts the CA GitHub uses (DigiCert), so for GitHub
# specifically this is largely ceremonial. For a custom OIDC provider
# (e.g. an internal service), this thumbprint would be essential.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Step 2: Register GitHub as a trusted OIDC Identity Provider in this AWS account.
#
# url          - GitHub's OIDC issuer URL. AWS fetches the openid-configuration
#                from here to discover the JWKS endpoint.
#
# client_id_list - The audience (aud) claim AWS will require in every JWT.
#                  "sts.amazonaws.com" means: this token was minted for AWS STS.
#                  A JWT with a different audience will be rejected.
#
# thumbprint_list - The root CA fingerprint from the step above. AWS checks
#                   this before trusting the public keys it fetches from GitHub.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}

# ---------------------------------------------------------------------------
# What comes next (Part D):
#   - An IAM role with a trust policy that references this provider's ARN
#   - Conditions on that trust policy that check the `sub` claim to restrict
#     access to only this specific GitHub repo and branch
# ---------------------------------------------------------------------------
