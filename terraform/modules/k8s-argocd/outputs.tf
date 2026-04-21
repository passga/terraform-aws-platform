output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  value = helm_release.argocd.name
}

output "initial_admin_secret_name" {
  value = "argocd-initial-admin-secret"
}

output "admin_password" {
  value     = data.kubernetes_secret_v1.argocd_initial_admin.data.password
  sensitive = true
}
