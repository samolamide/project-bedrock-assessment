terraform {
  backend "s3" {
    bucket = "project-bedrock-terraform-state-alt-soe-025-4363"
    key    = "project-bedrock/terraform.tfstate"
    region = "us-east-1"
  }
}
