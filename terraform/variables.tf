variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "project-bedrock-cluster"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "vpc_name" {
  description = "VPC Name tag"
  type        = string
  default     = "project-bedrock-vpc"
}

variable "assets_bucket_name" {
  description = "S3 bucket for marketing assets"
  type        = string
  default     = "bedrock-assets-alt-soe-025-4363"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the retail application"
  type        = string
  default     = "retail-app"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "FQDN for the retail store UI (required for HTTPS bonus). Leave empty for HTTP-only ALB."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Existing Route53 hosted zone ID for domain_name. If empty and domain_name is set, a new hosted zone is created."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization or username for OIDC trust"
  type        = string
  default     = "samolamide"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust"
  type        = string
  default     = "project-bedrock-assessment"
}

variable "create_github_oidc" {
  description = "Create GitHub OIDC provider and IAM role for CI/CD"
  type        = bool
  default     = true
}

variable "dev_view_user_create_login_profile" {
  description = "Create IAM console login profile for bedrock-dev-view"
  type        = bool
  default     = true
}
