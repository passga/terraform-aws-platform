
module "k8s_rancher_server" {
  source                  = "../../modules/k8s-rancher-server"
  rancher_version         = var.rancher_version
  kubeconfig_path         = var.kubeconfig_path
  rancher_hostname        = var.rancher_hostname
  letsencrypt_email       = var.letsencrypt_email
  letsencrypt_environment = var.letsencrypt_environment

}
