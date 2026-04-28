resource "null_resource" "wait_cert_manager_ready" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -euo pipefail

KUBECONFIG="${var.kubeconfig_path}"

echo "Waiting for cert-manager CRDs..."
for i in $(seq 1 60); do
  if kubectl --kubeconfig "$KUBECONFIG" get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
    echo "CRD clusterissuers.cert-manager.io is present"
    break
  fi
  echo "  ...($i/60)"
  sleep 5
done

echo "Waiting for cert-manager deployments..."
kubectl --kubeconfig "$KUBECONFIG" -n cert-manager rollout status deploy/cert-manager --timeout=5m
kubectl --kubeconfig "$KUBECONFIG" -n cert-manager rollout status deploy/cert-manager-webhook --timeout=5m
kubectl --kubeconfig "$KUBECONFIG" -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=5m

echo "cert-manager ready"
EOT
  }
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  depends_on = [null_resource.wait_cert_manager_ready]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = local.le_name }
    spec = {
      acme = {
        email               = var.letsencrypt_email
        server              = local.le_server_url
        privateKeySecretRef = { name = "${local.le_name}-account-key" }
        solvers = [{
          http01 = { ingress = { class = "traefik" } }
        }]
      }
    }
  }
}
