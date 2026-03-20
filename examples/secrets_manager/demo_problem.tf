# Read the secret at plan/apply time
# data "aws_secretsmanager_secret_version" "db" {
#   secret_id = aws_secretsmanager_secret.db_credentials.id
# }

# locals {
#   db = try(jsondecode(data.aws_secretsmanager_secret_version.db.secret_string), {})
# }

# WARNING:
# This would save secrets to state file
# resource "aws_db_instance" "mysql" {
#   engine         = "mysql"
#   engine_version = "8.0"
#   instance_class = "db.t3.micro"
#   db_name        = local.db["dbname"] # <== HERE
#   username       = local.db["username"] # <== HERE
#   password       = local.db["password"] # <== HERE
#   # ... other config
# }

# BEST PATTERN for RDS: let AWS manage the secret entirely.
# Terraform never sees the password at all.
#
# resource "aws_db_instance" "mysql" {
#   engine                      = "mysql"
#   engine_version              = "8.0"
#   instance_class              = "db.t3.micro"
#   db_name                     = "myapp"
#   username                    = "admin"
#   manage_master_user_password = true   # RDS creates and rotates the secret itself
# }
