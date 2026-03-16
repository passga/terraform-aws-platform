provider "rancher2" {
  api_url   = data.terraform_remote_state.rancher_server.outputs.rancher_server_url
  token_key = data.terraform_remote_state.rancher_server.outputs.rancher_server_token
  insecure  = var.rancher_insecure
}
