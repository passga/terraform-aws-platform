provider "kubernetes" {

  config_path = abspath(var.kubeconfig_path)
}

provider "helm" {
  kubernetes = {
    config_path = abspath(var.kubeconfig_path)
  }
}
