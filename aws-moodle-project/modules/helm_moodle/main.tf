resource "kubernetes_config_map" "moodle" {
  metadata {
    name = "moodle-config"
  }
  data = {
    SITE_MESSAGE = "Welcome to Moodle on AWS!"
  }
}

resource "helm_release" "moodle" {
  name       = "moodle"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "moodle"
  version    = "21.0.2"

  namespace          = "default"
  create_namespace   = false

  values = [
    templatefile("${path.module}/values.yaml", {
      rds_endpoint = var.rds_endpoint
      rds_password = var.rds_password
    })
  ]

  set = [
    {
      name  = "extraEnvVars[0].name"
      value = "SITE_MESSAGE"
    },
    {
      name  = "extraEnvVars[0].valueFrom.configMapKeyRef.name"
      value = kubernetes_config_map.moodle.metadata[0].name
    },
    {
      name  = "extraEnvVars[0].valueFrom.configMapKeyRef.key"
      value = "SITE_MESSAGE"
    }
  ]
}

resource "kubernetes_service" "moodle" {
  metadata {
    name = "moodle-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  spec {
    selector = {
      app = "moodle"
    }
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
  depends_on = [helm_release.moodle]
}

output "service_url" {
  value = kubernetes_service.moodle.status[0].load_balancer[0].ingress[0].hostname
  description = "ALB DNS name for Moodle access"
}