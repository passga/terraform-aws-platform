
data "terraform_remote_state" "platform_issuer" {
  backend = "local"

  config = {
    path = "../../platform/platform-issuer-root/terraform.tfstate"
  }
}

module "k8s_rancher_server" {
  source                          = "../../modules/k8s-rancher-server"
  rancher_version                 = var.rancher_version
  kubeconfig_path                 = var.kubeconfig_path
  rancher_hostname                = var.rancher_hostname
  rancher_bootstrap_insecure      = var.rancher_bootstrap_insecure
  rancher_bootstrap_wait_timeout  = var.rancher_bootstrap_wait_timeout
  rancher_tls_cluster_issuer_name = data.terraform_remote_state.platform_issuer.outputs.cluster_issuer_name
}
