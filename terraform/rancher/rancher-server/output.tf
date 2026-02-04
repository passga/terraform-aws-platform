
output "rancher_server_url" {
  value = "https://${var.rancher_hostname}"
}

# Required
output "rancher_server_dns" {
  value = var.rancher_hostname
}


# Required
output "rancher_server_token" {
  value = rancher2_bootstrap.admin.token
   sensitive = true
}

# Required
output "rancher_cli_token" {
  value     = rancher2_token.tokenCLI.token
  sensitive = true
}
