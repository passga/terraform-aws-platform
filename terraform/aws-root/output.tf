output "public_ip" {
  value = module.k3s_node.public_ip
}

output "hostname" {
  value = module.k3s_node.k3s_hostname
}

output "kubeconfig_path" {
  value = local.kubeconfig_path
}