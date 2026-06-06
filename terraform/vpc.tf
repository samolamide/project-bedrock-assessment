module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = [for i, az in local.azs : cidrsubnet("10.0.0.0/16", 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet("10.0.0.0/16", 4, i + length(local.azs))]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = merge(local.common_tags, {
    Name = var.vpc_name
  })
}

resource "aws_db_subnet_group" "data" {
  name       = "project-bedrock-data"
  subnet_ids = module.vpc.private_subnets

  tags = merge(local.common_tags, {
    Name = "project-bedrock-data"
  })
}
