# Creates the secret containers only. Values are populated via CLI after apply
#
# After apply, populate values with `aws secretsmanager put-secret-value ...`
# See phase2/README.md for instructions.

# Note: recovery_window_in_days is intentionally 0 so that we can tear down easily
# This is not a value to use in production without understanding its meaning

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "demo/app/db_credentials"
  description             = "JSON blob secret (e.g. database connection details)"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "demo/app/db_password"
  description             = "Plain string secret (database password)"
  recovery_window_in_days = 0
}

