# Look up the secret container created in phase1 by name

# db_credentials aren't used in all demos:
# tflint-ignore: terraform_unused_declarations
data "aws_secretsmanager_secret" "db_credentials" {
  name = "demo/app/db_credentials"
}

# db_password isn't used in all demos:
# tflint-ignore: terraform_unused_declarations
data "aws_secretsmanager_secret" "db_password" {
  name = "demo/app/db_password"
}
