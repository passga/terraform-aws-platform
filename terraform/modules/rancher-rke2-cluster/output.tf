output "cluster_id" {
  value = rancher2_cluster_v2.cluster.id
}

output "cluster_name" {
  value = rancher2_cluster_v2.cluster.name
}

output "cluster_v1_id" {
  value = rancher2_cluster_v2.cluster.cluster_v1_id
}

output "kubeconfig_path" {
  value = local_sensitive_file.kube_config_workload_yaml.filename
}
