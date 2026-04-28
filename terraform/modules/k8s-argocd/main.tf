resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name            = "argocd"
  namespace       = kubernetes_namespace.argocd.metadata[0].name
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  version         = var.argocd_chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      fullnameOverride = "argocd"
      configs = {
        params = {
          "server.insecure" = "true"
        }
      }
      server = {
        ingress = {
          enabled = false
        }
      }
    })
  ]

  wait    = true
  timeout = 600
}


data "kubernetes_secret_v1" "argocd_initial_admin" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
}


resource "kubernetes_ingress_v1" "argocd" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "argocd"
    namespace = kubernetes_namespace.argocd.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer"                   = var.cluster_issuer_name
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [var.hostname]
      secret_name = var.tls_secret_name
    }

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}