
output "rancher_server_url" {
  value = "https://${var.rancher_server_dns}"
}

# Required
output "rancher_server_dns" {
  value = var.rancher_server_dns
}


# Required
output "rancher_server_token" {
  value = rancher2_bootstrap.admin.token
}

# Required
output "rancher_cli_token" {
  value     = rancher2_token.tokenCLI.token
  sensitive = true
}
