data "aws_iam_policy_document" "github_oidc_assume" {
  count = var.create_github_oidc && var.github_org != "" && var.github_repo != "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd04d2831fd619398d64febc588548899438",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = local.common_tags
}

resource "aws_iam_role" "github_terraform" {
  count = var.create_github_oidc && var.github_org != "" && var.github_repo != "" ? 1 : 0

  name = "github-terraform-bedrock"

  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  count = var.create_github_oidc && var.github_org != "" && var.github_repo != "" ? 1 : 0

  role       = aws_iam_role.github_terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_eks_access_entry" "github_terraform" {
  count = var.create_github_oidc && var.github_org != "" && var.github_repo != "" ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_terraform[0].arn
  type          = "STANDARD"

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "github_terraform" {
  count = var.create_github_oidc && var.github_org != "" && var.github_repo != "" ? 1 : 0

  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.github_terraform[0].principal_arn

  access_scope {
    type = "cluster"
  }
}
