output "cluster_id" {
  value = module.downstream_rke2.cluster_id
}

output "cluster_name" {
  value = module.downstream_rke2.cluster_name
}

output "cluster_v1_id" {
  value = module.downstream_rke2.cluster_v1_id
}

output "kubeconfig_path" {
  value = module.downstream_rke2.kubeconfig_path
}

output "aws_region" {
  value = local.aws_region
}

output "aws_vpc_id" {
  value = local.aws_vpc_id
}

output "aws_subnet_id" {
  value = local.aws_subnet_id
}
