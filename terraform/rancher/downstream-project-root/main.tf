data "terraform_remote_state" "rancher_server" {
  backend = "local"

  config = {
    path = "../rancher-server-root/terraform.tfstate"
  }
}

data "terraform_remote_state" "downstream_rke2" {
  backend = "local"

  config = {
    path = "../downstream-rke2-root/terraform.tfstate"
  }
}

resource "rancher2_project" "project" {
  name        = var.project_name
  cluster_id  = data.terraform_remote_state.downstream_rke2.outputs.cluster_v1_id
  description = var.project_description
}

resource "rancher2_namespace" "namespace" {
  name        = var.namespace_name
  project_id  = rancher2_project.project.id
  description = var.namespace_description
}
