# Creates the secret containers only. Values are populated via CLI after apply
#
# After apply, populate values with:
#   aws secretsmanager put-secret-value \
#     --secret-id learning/app/api_key \
#     --secret-string "your-actual-value"

# Note: recovery_window_in_days is intentionally 0 so that we can tear down easily
# This is not a value to use in production without understanding its meaning

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "learning/app/api_key"
  description             = "Plain string secret - e.g. an API key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "learning/app/db_credentials"
  description             = "JSON blob secret - e.g. database connection details"
  recovery_window_in_days = 0
}
