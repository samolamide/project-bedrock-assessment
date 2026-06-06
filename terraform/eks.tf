module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  enable_cluster_creator_admin_permissions = true
  enable_irsa                            = true

  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    bedrock_nodes = {
      name           = "bedrock-nodes"
      instance_types = var.node_instance_types
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_desired_size

      subnet_ids = module.vpc.private_subnets
    }
  }

  tags = local.common_tags
}

resource "aws_security_group" "catalog_rds" {
  name        = "project-bedrock-catalog-rds"
  description = "Allow MySQL from EKS nodes to catalog RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "project-bedrock-catalog-rds"
  })
}

resource "aws_security_group" "orders_rds" {
  name        = "project-bedrock-orders-rds"
  description = "Allow PostgreSQL from EKS nodes to orders RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "project-bedrock-orders-rds"
  })
}

resource "aws_security_group" "catalog_pods" {
  name        = "project-bedrock-catalog-pods"
  description = "Security group for catalog pods (SecurityGroupPolicy)"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    Name = "project-bedrock-catalog-pods"
  })
}

resource "aws_security_group_rule" "catalog_rds_from_pods" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.catalog_rds.id
  source_security_group_id = aws_security_group.catalog_pods.id
  description              = "MySQL from catalog pods"
}

resource "aws_security_group" "orders_pods" {
  name        = "project-bedrock-orders-pods"
  description = "Security group for orders pods (SecurityGroupPolicy)"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    Name = "project-bedrock-orders-pods"
  })
}

resource "aws_security_group_rule" "orders_rds_from_pods" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.orders_rds.id
  source_security_group_id = aws_security_group.orders_pods.id
  description              = "PostgreSQL from orders pods"
}
