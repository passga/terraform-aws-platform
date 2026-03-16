resource "helm_release" "cert_manager" {

  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "startupapicheck.enabled"
      value = "false"
    }
  ]

  wait    = true
  timeout = 600
}

