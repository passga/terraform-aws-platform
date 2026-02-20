

output "rancher_server_url" {
  value       = local.rancher_api_url
  description = "Rancher UI/API base URL."
}

output "rancher_admin_password" {
  description = "Initial Rancher admin password (sensitive)."
  value       = random_password.rancher_admin.result
  sensitive   = true
}

