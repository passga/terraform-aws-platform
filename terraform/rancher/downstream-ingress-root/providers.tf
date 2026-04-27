locals {
  kubeconfig_path = (
    var.kubeconfig_path_override != null && trimspace(var.kubeconfig_path_override) != ""
    ? abspath(var.kubeconfig_path_override)
    : abspath("${path.module}/../downstream-rke2-root/${basename(data.terraform_remote_state.downstream_rke2.outputs.kubeconfig_path)}")
  )
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
    insecure    = true
  }
}
