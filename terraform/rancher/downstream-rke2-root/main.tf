
module "downstream_rke2" {
  source                      = "../../modules/rancher-rke2-cluster"
  access_key                  = var.access_key
  secret_key                  = var.secret_key
  cloud_credential_id         = var.cloud_credential_id
  aws_region                  = local.aws_region
  aws_zone                    = local.aws_zone
  aws_vpc_id                  = local.aws_vpc_id
  aws_subnet_id               = local.aws_subnet_id
  ec2_security_group_name     = local.ec2_security_group_name
  instance_type               = var.instance_type
  control_plane_quantity      = var.control_plane_quantity
  worker_quantity             = var.worker_quantity
  cluster_ready_wait_duration = var.cluster_ready_wait_duration
  rancher_api_url             = "https://${var.rancher_server_dns}"
  rancher_api_token           = data.terraform_remote_state.rancher_server.outputs.rancher_server_token
  rancher_insecure            = var.rancher_insecure
  workload_cluster_name       = var.workload_cluster_name
  workload_kubernetes_version = var.workload_kubernetes_version
  windows_prefered_cluster    = var.windows_prefered_cluster
  prefix                      = var.prefix
}
