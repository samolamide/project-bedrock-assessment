data "aws_secretsmanager_secret_version" "catalog_rds" {
  secret_id = module.catalog_rds.db_instance_master_user_secret_arn
}

data "aws_secretsmanager_secret_version" "orders_rds" {
  secret_id = module.orders_rds.db_instance_master_user_secret_arn
}

locals {
  catalog_db_creds = jsondecode(data.aws_secretsmanager_secret_version.catalog_rds.secret_string)
  orders_db_creds  = jsondecode(data.aws_secretsmanager_secret_version.orders_rds.secret_string)
}

resource "aws_secretsmanager_secret" "catalog_db" {
  name = "project-bedrock/catalog-db"

  tags = merge(local.common_tags, {
    Name = "project-bedrock-catalog-db"
  })
}

resource "aws_secretsmanager_secret_version" "catalog_db" {
  secret_id = aws_secretsmanager_secret.catalog_db.id

  secret_string = jsonencode({
    username = local.catalog_db_creds.username
    password = local.catalog_db_creds.password
    host     = module.catalog_rds.db_instance_address
    port     = module.catalog_rds.db_instance_port
    database = "catalog"
  })
}

resource "aws_secretsmanager_secret" "orders_db" {
  name = "project-bedrock/orders-db"

  tags = merge(local.common_tags, {
    Name = "project-bedrock-orders-db"
  })
}

resource "aws_secretsmanager_secret_version" "orders_db" {
  secret_id = aws_secretsmanager_secret.orders_db.id

  secret_string = jsonencode({
    username = local.orders_db_creds.username
    password = local.orders_db_creds.password
    host     = module.orders_rds.db_instance_address
    port     = module.orders_rds.db_instance_port
    database = "orders"
  })
}

resource "kubernetes_secret_v1" "catalog_db" {
  metadata {
    name      = "catalog-db"
    namespace = kubernetes_namespace_v1.retail_app.metadata[0].name
  }

  data = {
    RETAIL_CATALOG_PERSISTENCE_USER     = local.catalog_db_creds.username
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = local.catalog_db_creds.password
  }

  type = "Opaque"

  depends_on = [module.catalog_rds]
}

resource "kubernetes_secret_v1" "orders_db" {
  metadata {
    name      = "orders-db"
    namespace = kubernetes_namespace_v1.retail_app.metadata[0].name
  }

  data = {
    RETAIL_ORDERS_PERSISTENCE_USERNAME = local.orders_db_creds.username
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = local.orders_db_creds.password
  }

  type = "Opaque"

  depends_on = [module.orders_rds]
}
