# Helm resources


resource "kubernetes_namespace" "cattle_system" {
  metadata { name = "cattle-system" }
}

resource "time_sleep" "wait_certmanager_crds" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "30s"
}

# Install Rancher helm chart
resource "helm_release" "rancher_server" {


  depends_on = [
    time_sleep.wait_certmanager_crds
  ]

  repository       = "https://releases.rancher.com/server-charts/latest"
  name             = "rancher"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set  = [
    {
    name  = "hostname"
    value = var.rancher_hostname
   },

  {
    name  = "replicas"
    value = "1"
  },

   {
    name  = "bootstrapPassword"
    value = "admin" # TODO: change this once the terraform provider has been updated with the new pw bootstrap logic
  },

  # k3s => traefik default
   {
    name = "ingress.ingressClassName"
    value = "traefik"
  },

  # POC simple: auto signed certificated
   {
    name = "ingress.tls.source"
    value = "rancher"
  }]
}
