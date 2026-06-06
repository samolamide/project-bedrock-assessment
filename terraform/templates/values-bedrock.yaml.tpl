cart:
  fullnameOverride: carts
  image:
    repository: ${cart_image_repository}
    tag: "${cart_image_tag}"
  dynamodb:
    create: false
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${carts_role_arn}
  app:
    persistence:
      provider: dynamodb
      dynamodb:
        tableName: ${dynamodb_table_name}
        createTable: false

catalog:
  fullnameOverride: catalog
  image:
    repository: ${catalog_image_repository}
    tag: "${catalog_image_tag}"
  mysql:
    create: false
  securityGroups:
    create: false
  app:
    persistence:
      provider: mysql
      endpoint: "${catalog_db_endpoint}"
      database: catalog
      secret:
        create: false
        name: catalog-db
    search:
      enabled: false

checkout:
  fullnameOverride: checkout
  image:
    repository: ${checkout_image_repository}
    tag: "${checkout_image_tag}"
  redis:
    create: true
  app:
    persistence:
      provider: redis
    endpoints:
      orders: http://orders:80

orders:
  fullnameOverride: orders
  image:
    repository: ${orders_image_repository}
    tag: "${orders_image_tag}"
  postgresql:
    create: false
  rabbitmq:
    create: true
  securityGroups:
    create: false
  app:
    persistence:
      provider: postgres
      endpoint: "${orders_db_endpoint}"
      database: ${orders_db_name}
      secret:
        create: false
        name: orders-db
    messaging:
      provider: rabbitmq

ui:
  fullnameOverride: ui
  image:
    repository: ${ui_image_repository}
    tag: "${ui_image_tag}"
  app:
    endpoints:
      catalog: http://catalog:80
      carts: http://carts:80
      checkout: http://checkout:80
      orders: http://orders:80
  service:
    type: ClusterIP
  ingress:
    enabled: ${ingress_enabled}
    className: ${ingress_class}
    annotations:
%{ for key, value in ingress_annotations ~}
      ${key}: '${value}'
%{ endfor ~}
%{ if length(ingress_hosts) > 0 ~}
    hosts:
%{ for host in ingress_hosts ~}
      - "${host}"
%{ endfor ~}
%{ endif ~}
