locals {
  common_tags = {
    Project = "karatu-2025-capstone"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  images = {
    catalog = {
      repository = "public.ecr.aws/aws-containers/retail-store-sample-catalog"
      tag        = "1.6.1"
    }
    cart = {
      repository = "public.ecr.aws/aws-containers/retail-store-sample-cart"
      tag        = "1.6.1"
    }
    checkout = {
      repository = "public.ecr.aws/aws-containers/retail-store-sample-checkout"
      tag        = "1.6.1"
    }
    orders = {
      repository = "public.ecr.aws/aws-containers/retail-store-sample-orders"
      tag        = "1.6.1"
    }
    ui = {
      repository = "public.ecr.aws/aws-containers/retail-store-sample-ui"
      tag        = "1.6.1"
    }
  }

  enable_tls = var.domain_name != ""

  route53_zone_id = local.enable_tls ? (
    var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.app[0].zone_id
  ) : ""

  ingress_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"         = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"    = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
    },
    local.enable_tls ? {
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443},{\"HTTP\":80}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.app[0].arn
    } : {
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
    }
  )

  ingress_hosts = local.enable_tls ? [var.domain_name] : []
}
