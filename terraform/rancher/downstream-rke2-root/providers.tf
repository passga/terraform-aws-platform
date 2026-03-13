provider "aws" {
  region = local.aws_region
}

provider "rancher2" {
  api_url   = "https://${var.rancher_server_dns}"
  token_key = data.terraform_remote_state.rancher_server.outputs.rancher_server_token
  insecure  = var.rancher_insecure
}
