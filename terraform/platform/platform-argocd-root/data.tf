data "terraform_remote_state" "downstream_rke2" {
  backend = "local"

  config = {
    path = "../../rancher/downstream-rke2-root/terraform.tfstate"
  }
}

data "terraform_remote_state" "platform_issuer" {
  backend = "local"

  config = {
    path = "../platform-issuer-root/terraform.tfstate"
  }
}
