module "carts_dynamodb" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.3"

  name     = "project-bedrock-carts"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "customerId"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "idx_global_customerId"
      hash_key        = "customerId"
      projection_type = "ALL"
    }
  ]

  tags = merge(local.common_tags, {
    Name = "project-bedrock-carts"
  })
}

resource "aws_iam_policy" "carts_dynamodb" {
  name        = "project-bedrock-carts-dynamo"
  description = "DynamoDB access for carts service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          module.carts_dynamodb.dynamodb_table_arn,
          "${module.carts_dynamodb.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

module "carts_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58"

  role_name = "project-bedrock-carts-dynamo"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.app_namespace}:carts"]
    }
  }

  role_policy_arns = {
    dynamodb = aws_iam_policy.carts_dynamodb.arn
  }

  tags = local.common_tags
}
