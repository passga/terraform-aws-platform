# Helm provider

# Rancher2 bootstrapping provider
provider "rancher2" {
  api_url  = "https://${var.rancher_server_dns}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = var.rancher_server_token
}
