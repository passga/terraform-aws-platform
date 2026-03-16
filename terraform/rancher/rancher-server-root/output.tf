output "rancher_server_url" {
  value = module.k8s_rancher_server.rancher_server_url
}

output "rancher_admin_password" {
  value     = module.k8s_rancher_server.rancher_admin_password
  sensitive = true
}

output "rancher_server_token" {
  value     = module.k8s_rancher_server.rancher_server_token
  sensitive = true
}
