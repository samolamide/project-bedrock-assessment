resource "random_password" "catalog_db" {
  length  = 16
  special = false
}

resource "random_password" "orders_db" {
  length  = 16
  special = false
}

module "catalog_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "project-bedrock-catalog"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = true

  db_name  = "catalog"
  username = "catalog"
  password = random_password.catalog_db.result
  port     = 3306

  vpc_security_group_ids = [aws_security_group.catalog_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.data.name

  publicly_accessible = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = merge(local.common_tags, {
    Name = "project-bedrock-catalog"
  })
}

module "orders_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "project-bedrock-orders"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = true

  db_name  = "orders"
  username = "orders"
  password = random_password.orders_db.result
  port     = 5432

  vpc_security_group_ids = [aws_security_group.orders_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.data.name

  publicly_accessible = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = merge(local.common_tags, {
    Name = "project-bedrock-orders"
  })
}
