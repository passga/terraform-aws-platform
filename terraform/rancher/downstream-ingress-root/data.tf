data "terraform_remote_state" "downstream_rke2" {
  backend = "local"

  config = {
    path = "../downstream-rke2-root/terraform.tfstate"
  }
}

data "kubernetes_service" "rke2_traefik" {
  metadata {
    name      = "rke2-traefik"
    namespace = "kube-system"
  }

  depends_on = [kubernetes_manifest.rke2_traefik_config]
}
