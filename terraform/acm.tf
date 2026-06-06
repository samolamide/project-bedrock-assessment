resource "aws_route53_zone" "app" {
  count = local.enable_tls && var.route53_zone_id == "" ? 1 : 0

  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = "project-bedrock-dns"
  })
}

resource "aws_acm_certificate" "app" {
  count = local.enable_tls ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "project-bedrock-ui-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.enable_tls ? {
    for dvo in aws_acm_certificate.app[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

resource "aws_acm_certificate_validation" "app" {
  count = local.enable_tls ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "app" {
  count = local.enable_tls ? 1 : 0

  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_ingress_v1.ui.status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [helm_release.retail_app]
}
