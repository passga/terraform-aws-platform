output "rancher_admin_password" {
  value     = module.k8s_rancher_server.rancher_admin_password
  sensitive = true
}