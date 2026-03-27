data "terraform_remote_state" "downstream_rke2" {
  backend = "local"

  config = {
    path = "../downstream-rke2-root/terraform.tfstate"
  }
}

data "kubernetes_service_v1" "rke2_traefik" {
  metadata {
    name      = "rke2-traefik"
    namespace = "kube-system"
  }
}
