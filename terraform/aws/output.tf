
output "rancher_server_url" {
  value = "https://${var.rancher_server_dns}"
}


output "rancher_node_ip" {
  value = aws_eip_association.rancher_server.public_ip
}

output "rancher_server_ec2_instance_id" {
  value = aws_eip_association.rancher_server.instance_id
}

output "tokenRancherCLI" {
  value = module.rancher_server.rancher_cli_token
  sensitive = true
}

output "rancher_server_subnet_id" {
  value = aws_instance.rancher_server.subnet_id
  sensitive = true
}

output "rancher_server_availability_zone" {
  value = aws_instance.rancher_server.availability_zone
  sensitive = true
}

/*
output "perf_workload_node_ip" {
  value = module.rancher_rke.perf_workload_node_ip
}

output "perf_workload_worker_worker_ip" {
  value = module.rancher_rke.perf_workload_worker_worker_ip
}
*/

output "project_id" {
  value = module.rancher_rke.performance_project_id
}


