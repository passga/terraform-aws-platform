# Rancher2 administration provider
provider "rancher2" {
  alias = "admin"

  api_url  = "https://${var.rancher_hostname}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = rancher2_bootstrap.admin.token
}



# Rancher2 bootstrapping provider
provider "rancher2" {
  alias = "bootstrap"

  api_url  = "https://${var.rancher_hostname}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  bootstrap = true
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes ={
    config_path = var.kubeconfig_path
  }
}

