module "k8s_cert_manager" {
  source               = "../../modules/k8s-cert-manager"
  kubeconfig_path      = var.kubeconfig_path
  cert_manager_version = var.cert_manager_version
}

# Optional but helps avoid race conditions after helm reports "deployed"
resource "time_sleep" "after_cert_manager" {
  depends_on      = [module.k8s_cert_manager]
  create_duration = "10s"
}
