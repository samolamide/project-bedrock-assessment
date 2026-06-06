# Project Bedrock — InnovateMart EKS Capstone

Production-grade AWS EKS deployment for the [AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app), automated with Terraform and GitHub Actions.

## Architecture

```
Internet → ALB (HTTPS) → UI (retail-app namespace)
                              ↓
         Catalog ← RDS MySQL    Carts ← DynamoDB (IRSA)
         Orders  ← RDS PostgreSQL + RabbitMQ (in-cluster)
         Checkout ← Redis (in-cluster)

S3 (bedrock-assets-alt-soe-025-4363) → Lambda (bedrock-asset-processor) → CloudWatch Logs
EKS Control Plane + Pods → CloudWatch Logs (Observability add-on)
```

See [docs/architecture.md](docs/architecture.md) for the full diagram.

## Prerequisites

- AWS account with admin access
- [AWS CLI](https://aws.amazon.com/cli/) configured
- [Terraform](https://www.terraform.io/) >= 1.5
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/) >= 3.14
- GitHub repository (for CI/CD)

## Quick Start

### 1. Bootstrap remote state (one-time)

```bash
cd terraform/bootstrap
terraform init
terraform apply
cd ..
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set github_org, github_repo, and optionally domain_name for HTTPS
```

### 3. Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

First apply takes ~25–40 minutes (EKS, RDS, ALB).

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
kubectl get pods -n retail-app
```

### 5. Access the store

```bash
terraform output retail_app_url
```

Or with HTTPS (when `domain_name` is configured):

```
https://<your-domain>
```

### 6. Generate grading.json

```bash
terraform output -json > ../grading.json
```

## Helm deployment (manual alternative)

Terraform deploys the app automatically. To redeploy manually:

```bash
helm dependency update retail-store-sample-app/src/app/chart
helm upgrade --install retail-app retail-store-sample-app/src/app/chart \
  -n retail-app --create-namespace \
  -f helm/values-bedrock.yaml
```

## CI/CD (GitHub Actions)

### Setup OIDC (recommended)

1. Set `github_org` and `github_repo` in `terraform.tfvars`
2. Run `terraform apply` to create the `github-terraform-bedrock` IAM role
3. Add GitHub repository secret:
   - `AWS_ROLE_ARN` = output `github_actions_role_arn`

### Pipeline behavior

| Event | Action |
|---|---|
| Pull request to `main` | `terraform plan` posted as PR comment |
| Merge to `main` | `terraform apply` + update `grading.json` |

### Fallback (access keys)

Replace the OIDC step in `.github/workflows/terraform.yml` with:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

## Developer access (`bedrock-dev-view`)

After apply, credentials are written to `bedrock-dev-view-credentials.txt` (gitignored).

**AWS Console:** ReadOnlyAccess + S3 PutObject on assets bucket  
**Kubernetes:** Read-only cluster access (`AmazonEKSViewPolicy`)

```bash
# As bedrock-dev-view
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
kubectl get pods -n retail-app          # succeeds
kubectl delete pod -n retail-app <name> # fails (Forbidden)
```

## HTTPS bonus (TLS)

1. Set `domain_name` in `terraform.tfvars`
2. If creating a new Route53 zone, delegate NS records at your registrar:
   ```bash
   terraform output route53_name_servers
   ```
3. Re-apply — ACM DNS validation and ALB HTTPS listener are configured automatically

## Verification checklist

- [ ] `terraform output` shows: `cluster_endpoint`, `cluster_name`, `region`, `vpc_id`, `assets_bucket_name`
- [ ] All pods running in `retail-app` namespace
- [ ] Store UI accessible via ALB/HTTPS URL
- [ ] CloudWatch: EKS control plane + container logs visible
- [ ] Upload to S3 as `bedrock-dev-view` triggers Lambda log: `Image received: <filename>`
- [ ] All AWS resources tagged `Project: karatu-2025-capstone`

## Teardown (avoid ongoing charges)

```bash
cd terraform
terraform destroy
```

Also destroy bootstrap state bucket if no longer needed.

## Project constraints

| Resource | Value |
|---|---|
| Region | us-east-1 |
| EKS Cluster | project-bedrock-cluster |
| VPC | project-bedrock-vpc |
| Namespace | retail-app |
| IAM User | bedrock-dev-view |
| S3 Bucket | bedrock-assets-alt-soe-025-4363 |
| Lambda | bedrock-asset-processor |
| Tag | Project=karatu-2025-capstone |

## Submission

1. Push repo (public or grant access)
2. Include `grading.json` at repo root
3. Submit Google Doc with repo link, architecture diagram, app URL, and `bedrock-dev-view` credentials to the course form
