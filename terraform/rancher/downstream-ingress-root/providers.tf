provider "aws" {
  region = data.terraform_remote_state.downstream_rke2.outputs.aws_region
}

provider "kubernetes" {
  config_path = abspath(data.terraform_remote_state.downstream_rke2.outputs.kubeconfig_path)
  insecure    = true
}

provider "helm" {
  kubernetes = {
    config_path = abspath(data.terraform_remote_state.downstream_rke2.outputs.kubeconfig_path)
    insecure    = true
  }
}
