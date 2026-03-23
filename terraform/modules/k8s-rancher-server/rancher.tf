
resource "kubernetes_namespace" "cattle_system" {
  metadata { name = "cattle-system" }
}


resource "kubernetes_manifest" "rancher_certificate" {
  depends_on = [
    kubernetes_namespace.cattle_system
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "rancher-tls"
      namespace = "cattle-system"
    }

    spec = {
      secretName = "rancher-tls"
      issuerRef = {
        name = var.rancher_tls_cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [var.rancher_hostname]
    }
  }
}

# Install Rancher helm chart
resource "helm_release" "rancher_server" {
  depends_on = [
    kubernetes_manifest.rancher_certificate
  ]

  repository       = "https://releases.rancher.com/server-charts/latest"
  name             = "rancher"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = "cattle-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600
  wait             = true

  set = [
    {
      name  = "hostname"
      value = var.rancher_hostname
    },
    {
      name  = "replicas"
      value = "1"
    },
    # Initial admin password (used by rancher2_bootstrap)
    {
      name  = "bootstrapPassword"
      value = random_password.rancher_admin.result
    },
    # k3s => traefik default
    {
      name  = "ingress.ingressClassName"
      value = "traefik"
    },
    # Use a public, trusted TLS cert (no insecure flags needed)
    { name = "ingress.tls.source", value = "secret" },
    { name = "ingress.tls.secretName", value = "rancher-tls" },
    { name = "agentTLSMode", value = "system-store" }


  ]
}

resource "null_resource" "wait_rancher_api" {
  depends_on = [
    kubernetes_manifest.rancher_certificate,
    helm_release.rancher_server
  ]

  triggers = {
    rancher_hostname          = var.rancher_hostname
    rancher_api_url           = local.rancher_api_url
    rancher_tls_secret_name   = "rancher-tls"
    rancher_tls_certificate   = "rancher-tls"
    bootstrap_password_sha256 = sha256(random_password.rancher_admin.result)
    bootstrap_wait_timeout    = var.rancher_bootstrap_wait_timeout
    bootstrap_insecure        = tostring(var.rancher_bootstrap_insecure)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG_PATH            = abspath(var.kubeconfig_path)
      RANCHER_HOSTNAME           = var.rancher_hostname
      RANCHER_URL                = local.rancher_api_url
      RANCHER_BOOTSTRAP_PASSWORD = random_password.rancher_admin.result
      TIMEOUT_DURATION           = var.rancher_bootstrap_wait_timeout
      RANCHER_INSECURE           = tostring(var.rancher_bootstrap_insecure)
    }

    command = "/bin/bash ${path.root}/../../../tools/scripts/wait-for-rancher.sh"
  }
}

resource "rancher2_bootstrap" "bootstrap" {
  depends_on       = [null_resource.wait_rancher_api]
  provider         = rancher2
  initial_password = random_password.rancher_admin.result
  password         = random_password.rancher_admin.result
}

resource "null_resource" "cleanup_rancher_destroy" {
  depends_on = [
    kubernetes_namespace.cattle_system,
    helm_release.rancher_server,
    rancher2_bootstrap.bootstrap
  ]

  triggers = {
    kubeconfig_path = abspath(var.kubeconfig_path)
    namespace       = "cattle-system"
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG_PATH   = self.triggers.kubeconfig_path
      RANCHER_NAMESPACE = self.triggers.namespace
    }

    command = "/bin/bash ${path.root}/../../tools/scripts/cleanup-rancher-destroy.sh"
  }
}
