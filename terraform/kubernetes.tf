resource "kubernetes_namespace_v1" "retail_app" {
  metadata {
    name = var.app_namespace

    labels = {
      name = var.app_namespace
    }
  }

  depends_on = [module.eks]
}

resource "time_sleep" "wait_for_cluster" {
  create_duration = "60s"

  depends_on = [module.eks]
}

resource "helm_release" "retail_app" {
  name              = "retail-app"
  chart             = "${path.module}/../retail-store-sample-app/src/app/chart"
  namespace         = kubernetes_namespace_v1.retail_app.metadata[0].name
  create_namespace  = false
  dependency_update = true
  timeout           = 900
  wait              = true

  values = [
    templatefile("${path.module}/templates/values-bedrock.yaml.tpl", {
      catalog_image_repository  = local.images.catalog.repository
      catalog_image_tag         = local.images.catalog.tag
      cart_image_repository     = local.images.cart.repository
      cart_image_tag            = local.images.cart.tag
      checkout_image_repository = local.images.checkout.repository
      checkout_image_tag        = local.images.checkout.tag
      orders_image_repository   = local.images.orders.repository
      orders_image_tag          = local.images.orders.tag
      ui_image_repository       = local.images.ui.repository
      ui_image_tag              = local.images.ui.tag
      catalog_db_endpoint       = "${module.catalog_rds.db_instance_address}:${module.catalog_rds.db_instance_port}"
      orders_db_endpoint        = "${module.orders_rds.db_instance_address}:${module.orders_rds.db_instance_port}"
      orders_db_name            = "orders"
      catalog_security_group    = aws_security_group.catalog_pods.id
      orders_security_group     = aws_security_group.orders_pods.id
      carts_role_arn            = module.carts_irsa.iam_role_arn
      dynamodb_table_name       = module.carts_dynamodb.dynamodb_table_id
      ingress_enabled           = true
      ingress_class             = "alb"
      ingress_annotations       = local.ingress_annotations
      ingress_hosts             = local.ingress_hosts
    })
  ]

  depends_on = [
    time_sleep.wait_for_cluster,
    kubernetes_secret_v1.catalog_db,
    kubernetes_secret_v1.orders_db,
    module.carts_irsa,
    aws_acm_certificate_validation.app,
    helm_release.aws_load_balancer_controller,
  ]
}

data "kubernetes_ingress_v1" "ui" {
  metadata {
    name      = "ui"
    namespace = var.app_namespace
  }

  depends_on = [helm_release.retail_app]
}
