# Local resources

locals {
  normalized_prefix        = trimspace(var.prefix)
  cluster_name_has_prefix  = local.normalized_prefix != "" && (var.workload_cluster_name == local.normalized_prefix || startswith(var.workload_cluster_name, "${local.normalized_prefix}-") || endswith(var.workload_cluster_name, "-${local.normalized_prefix}") || strcontains(var.workload_cluster_name, "-${local.normalized_prefix}-"))
  kubeconfig_filename_base = local.cluster_name_has_prefix || local.normalized_prefix == "" ? var.workload_cluster_name : "${local.normalized_prefix}-${var.workload_cluster_name}"
  kubeconfig_filename      = "${local.kubeconfig_filename_base}-kubeconfig.yaml"
}

# Save kubeconfig locally without storing the content in plaintext state.
resource "local_sensitive_file" "kube_config_workload_yaml" {
  filename = format("%s/%s", path.root, local.kubeconfig_filename)
  content  = rancher2_cluster_v2.cluster.kube_config
}

locals {
  control_plane_pool = {
    name               = "${var.prefix}-control-plane"
    quantity           = var.control_plane_quantity
    control_plane_role = true
    etcd_role          = true
    worker_role        = false
  }

  worker_pool = {
    name               = "${var.prefix}-worker"
    quantity           = var.worker_quantity
    control_plane_role = false
    etcd_role          = false
    worker_role        = true
  }

  rke_network_plugin = var.windows_prefered_cluster ? "flannel" : "canal"
  aws_zone_suffix    = trimprefix(var.aws_zone, var.aws_region)
}

