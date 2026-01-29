
resource "sshcommand_command" "install_k3s" {
  host        = var.node_public_ip
  command     = "bash -c 'curl https://get.k3s.io | INSTALL_K3S_EXEC=\"server --node-external-ip ${var.node_public_ip} --node-ip ${var.node_internal_ip}\" INSTALL_K3S_VERSION=${var.rancher_kubernetes_version} sh -'"
  user        = var.node_username
  private_key = var.ssh_private_key_pem
}

resource "sshcommand_command" "retrieve_config" {
  depends_on  = [
    sshcommand_command.install_k3s
  ]
  host        = var.node_public_ip
  command     = "sudo sed \"s/127.0.0.1/${var.node_public_ip}/g\" /etc/rancher/k3s/k3s.yaml"
  user        = var.node_username
  private_key = var.ssh_private_key_pem
}

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
  ttl = 0
  provider  = rancher2.admin
}