
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
        name = local.le_name
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
    { name = "ingress.tls.secretName", value = "rancher-tls" }


  ]
}


########################################
# Wait SSH (instance + EIP + sshd ready)
########################################
resource "null_resource" "wait_rancher_pong" {
  depends_on = [helm_release.rancher_server]

  provisioner "local-exec" {
    command = <<EOT
set -e
for i in $(seq 1 60); do
  if curl -kfsS "https://${var.rancher_hostname}/ping" | grep -qi pong; then
    echo "Rancher is ready"
    exit 0
  fi
  echo "Waiting for Rancher... ($i/60)"
  sleep 5
done
echo "Rancher not ready in time"
exit 1
EOT
  }
}

resource "rancher2_bootstrap" "bootstrap" {
  depends_on = [null_resource.wait_rancher_pong]
  provider = rancher2
  # premier bootstrap : initial_password est généralement "admin"
  initial_password = random_password.rancher_admin.result
  password         = random_password.rancher_admin.result
}

