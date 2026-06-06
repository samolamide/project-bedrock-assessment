resource "aws_iam_user" "bedrock_dev_view" {
  name = "bedrock-dev-view"

  tags = merge(local.common_tags, {
    Name = "bedrock-dev-view"
  })
}

resource "aws_iam_user_policy_attachment" "bedrock_dev_view_readonly" {
  user       = aws_iam_user.bedrock_dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy" "bedrock_dev_view_s3" {
  name = "bedrock-assets-putobject"
  user = aws_iam_user.bedrock_dev_view.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.assets.arn
      },
      {
        Sid    = "PutObject"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

resource "aws_iam_access_key" "bedrock_dev_view" {
  user = aws_iam_user.bedrock_dev_view.name
}

resource "aws_iam_user_login_profile" "bedrock_dev_view" {
  count = var.dev_view_user_create_login_profile ? 1 : 0

  user                    = aws_iam_user.bedrock_dev_view.name
  password_reset_required = true
}

resource "aws_eks_access_entry" "bedrock_dev_view" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_user.bedrock_dev_view.arn
  type          = "STANDARD"

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "bedrock_dev_view" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_eks_access_entry.bedrock_dev_view.principal_arn

  access_scope {
    type = "cluster"
  }
}

resource "local_file" "bedrock_dev_view_credentials" {
  filename        = "${path.module}/../bedrock-dev-view-credentials.txt"
  file_permission = "0600"

  content = <<-EOT
    # bedrock-dev-view credentials — DO NOT COMMIT (listed in .gitignore)
    IAM User: bedrock-dev-view
    Access Key ID: ${aws_iam_access_key.bedrock_dev_view.id}
    Secret Access Key: ${aws_iam_access_key.bedrock_dev_view.secret}
    Console URL: https://${var.region}.signin.aws.amazon.com/console
    Console Username: bedrock-dev-view
    Console Password: ${var.dev_view_user_create_login_profile ? aws_iam_user_login_profile.bedrock_dev_view[0].password : "(login profile disabled)"}
  EOT

  depends_on = [
    aws_iam_access_key.bedrock_dev_view,
    aws_iam_user_login_profile.bedrock_dev_view
  ]
}
