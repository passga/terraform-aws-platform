
########################################
# Wait SSH (instance + EIP + sshd ready)
########################################

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]

  provider  = rancher2.bootstrap
  password  = var.rancher_server_admin_password
  telemetry = false
}

# Create a new rancher2 Token
resource "rancher2_token" "tokenCLI" {
  description = "Rancher CLI Token"
  ttl         = 0
  provider    = rancher2.admin
}