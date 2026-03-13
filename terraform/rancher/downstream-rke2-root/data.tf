data "terraform_remote_state" "aws_root" {
  count   = local.use_aws_root_remote_state ? 1 : 0
  backend = "local"

  config = {
    path = "../../aws-root/terraform.tfstate"
  }
}

data "terraform_remote_state" "rancher_server" {
  backend = "local"

  config = {
    path = "../rancher-server-root/terraform.tfstate"
  }
}
