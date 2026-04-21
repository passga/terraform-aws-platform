output "namespace" {
  value = module.k8s_argocd.namespace
}

output "release_name" {
  value = module.k8s_argocd.release_name
}

output "downstream_cluster_id" {
  value = data.terraform_remote_state.downstream_rke2.outputs.cluster_id
}

output "argocd_url" {
  value = "https://${var.argocd_hostname}"
}

output "argocd_initial_admin_secret_name" {
  value = module.k8s_argocd.initial_admin_secret_name
}

output "argocd_admin_password" {
  value     = module.k8s_argocd.admin_password
  sensitive = true
}
