provider "kubernetes" {

  config_path = abspath(var.kubeconfig_path)
  insecure    = true
}

provider "helm" {
  kubernetes = {
    config_path = abspath(var.kubeconfig_path)
    insecure    = true
  }
}
