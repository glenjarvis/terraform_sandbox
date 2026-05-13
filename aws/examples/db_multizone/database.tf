
module "primary_db" {
  source = "../../modules/data_stores/mysql"
  providers = {
    aws = aws.primary
  }

  project                 = "multizone-example"
  db_name                 = "main_db"
  db_username             = var.db_username
  db_password             = var.db_password
  backup_retention_period = 1
}

module "replica_db" {
  source = "../../modules/data_stores/mysql"
  providers = {
    aws = aws.replica
  }

  project = "multizone-example"
  # Make this a replica of the primary:
  replicate_source_db = module.primary_db.arn
}

