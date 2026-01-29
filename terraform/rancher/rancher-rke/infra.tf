# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "perf_node" {
  name        = "perf_node"
  description = "Terraform cloudCredential performance test"
  amazonec2_credential_config {
    access_key = var.access_key
    secret_key = var.secret_key
  }
}

resource "rancher2_cluster" "perf_cluster" {
  name        = var.workload_cluster_name
  description = "${var.prefix} rancher2 custom cluster"
  depends_on = [rancher2_node_template.perf_cluster_template_ec2]
  rke_config {
    network {
      plugin  = local.rke_network_plugin
      options = local.rke_network_options
    }
    kubernetes_version = var.workload_kubernetes_version
  }
}


# Create a new rancher2 Node Template
resource "rancher2_node_template" "perf_cluster_template_ec2" {
  name                = "${var.workload_cluster_name} node template"
  description         = "aws node template gvo"
  cloud_credential_id = rancher2_cloud_credential.perf_node.id
  engine_install_url = var.dockerurl
  amazonec2_config {
    ami            = data.aws_ami.ubuntu.id
    instance_type  = var.instance_type
    region         = var.aws_region
    subnet_id      = var.aws_subnet_id
    root_size      = 8
    security_group = [var.ec2_security_group_name]
    vpc_id         = var.aws_vpc_id
    zone           = var.aws_zone

  }
}
# Create a new rancher2 Node Pool
resource "rancher2_node_pool" "master" {
  cluster_id       = rancher2_cluster.perf_cluster.id
  name             = "${var.prefix}-workload-master "
  hostname_prefix  = "${var.prefix}-master"
  node_template_id = rancher2_node_template.perf_cluster_template_ec2.id
  quantity         = 1
  control_plane    = true
  etcd             = true
  worker           = true
}

# Create a new rancher2 Node Pool
resource "rancher2_node_pool" "worker" {
  cluster_id       = rancher2_cluster.perf_cluster.id
  name             = "${var.prefix}-workload-worker"
  hostname_prefix  = "${var.prefix}-worker"
  node_template_id = rancher2_node_template.perf_cluster_template_ec2.id
  quantity         = 1
  worker           = true
  depends_on = [rancher2_node_pool.master]
}


resource "rancher2_cluster_sync" "perf-provisioning_workload_sync" {
  provider      = rancher2
  cluster_id    = rancher2_cluster.perf_cluster.id
  node_pool_ids = [rancher2_node_pool.master.id, rancher2_node_pool.worker.id]
  depends_on = [rancher2_node_pool.worker]
}

# Create a new rancher2 Project
resource "rancher2_project" "init-project" {
  name        = var.prefix
  cluster_id  = rancher2_cluster_sync.perf-provisioning_workload_sync.id
  provider    = rancher2
  description = "${var.prefix} project for running of performance tests"
}

# Create a new rancher2 Namespace
resource "rancher2_namespace" "init-namespace" {
  name        = var.prefix
  project_id  = rancher2_project.init-project.id
  provider    = rancher2
  description = "${var.prefix} namespace for running of performance tests"
}

locals {
  rke_network_plugin  = var.windows_prefered_cluster ? "flannel" : "canal"
  rke_network_options = var.windows_prefered_cluster ? {
    flannel_backend_port = "4789"
    flannel_backend_type = "vxlan"
    flannel_backend_vni  = "4096"
  } : null
}
