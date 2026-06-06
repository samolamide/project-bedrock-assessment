output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "assets_bucket_name" {
  description = "Marketing assets S3 bucket name"
  value       = aws_s3_bucket.assets.id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

output "retail_app_url" {
  description = "URL to access the retail store UI"
  value = local.enable_tls ? "https://${var.domain_name}" : (
    length(data.kubernetes_ingress_v1.ui.status) > 0 && length(data.kubernetes_ingress_v1.ui.status[0].load_balancer) > 0 ?
    "http://${data.kubernetes_ingress_v1.ui.status[0].load_balancer[0].ingress[0].hostname}" :
    "Pending - run: kubectl get ingress -n ${var.app_namespace} ui"
  )
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = length(aws_iam_role.github_terraform) > 0 ? aws_iam_role.github_terraform[0].arn : null
}

output "route53_name_servers" {
  description = "Route53 name servers for TLS domain (delegate at registrar when creating new zone)"
  value       = local.enable_tls && var.route53_zone_id == "" ? aws_route53_zone.app[0].name_servers : []
}

output "bedrock_dev_view_access_key_id" {
  description = "Access key ID for bedrock-dev-view (also written to bedrock-dev-view-credentials.txt)"
  value       = aws_iam_access_key.bedrock_dev_view.id
  sensitive   = true
}

output "bedrock_dev_view_secret_access_key" {
  description = "Secret access key for bedrock-dev-view"
  value       = aws_iam_access_key.bedrock_dev_view.secret
  sensitive   = true
}

output "catalog_rds_endpoint" {
  description = "Catalog RDS endpoint"
  value       = module.catalog_rds.db_instance_endpoint
}

output "orders_rds_endpoint" {
  description = "Orders RDS endpoint"
  value       = module.orders_rds.db_instance_endpoint
}

output "dynamodb_table_name" {
  description = "Carts DynamoDB table name"
  value       = module.carts_dynamodb.dynamodb_table_id
}
