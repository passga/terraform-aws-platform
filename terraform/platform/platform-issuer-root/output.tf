output "letsencrypt_environment" {
  value = var.letsencrypt_environment
}

output "cluster_issuer_name" {
  value = local.le_name
}
