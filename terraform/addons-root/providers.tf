provider "kubernetes" {

  config_path = abspath(var.kubeconfig_path)
}

provider "helm" {
  kubernetes = {
    config_path = abspath(var.kubeconfig_path)
  }
}

# Default rancher2 provider (required if any resource/module references rancher2 without alias)
provider "rancher2" {
  api_url   = local.rancher_api_url
  insecure  = var.rancher_bootstrap_insecure
  bootstrap = true
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = local.rancher_api_url
  bootstrap = true
  insecure  = var.rancher_bootstrap_insecure
}

