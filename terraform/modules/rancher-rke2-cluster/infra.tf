# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "node" {
  count       = var.cloud_credential_id != null && trimspace(var.cloud_credential_id) != "" ? 0 : 1
  name        = "${var.workload_cluster_name}-node"
  description = "Terraform cloudCredential performance test"
  amazonec2_credential_config {
    access_key = var.access_key
    secret_key = var.secret_key
  }
}

locals {
  cloud_credential_id = var.cloud_credential_id != null && trimspace(var.cloud_credential_id) != "" ? trimspace(var.cloud_credential_id) : rancher2_cloud_credential.node[0].id
}

resource "rancher2_cluster_v2" "cluster" {
  name                  = var.workload_cluster_name
  enable_network_policy = false

  rke_config {
    machine_global_config = yamlencode({
      cni = local.rke_network_plugin
    })

    machine_pools {
      name     = local.control_plane_pool.name
      quantity = local.control_plane_pool.quantity

      control_plane_role = local.control_plane_pool.control_plane_role
      etcd_role          = local.control_plane_pool.etcd_role
      worker_role        = local.control_plane_pool.worker_role

      cloud_credential_secret_name = local.cloud_credential_id

      machine_config {
        kind = rancher2_machine_config_v2.cluster_template_ec2.kind
        name = rancher2_machine_config_v2.cluster_template_ec2.name
      }
    }

    machine_pools {
      name     = local.worker_pool.name
      quantity = local.worker_pool.quantity

      control_plane_role = local.worker_pool.control_plane_role
      etcd_role          = local.worker_pool.etcd_role
      worker_role        = local.worker_pool.worker_role

      cloud_credential_secret_name = local.cloud_credential_id

      machine_config {
        kind = rancher2_machine_config_v2.cluster_template_ec2.kind
        name = rancher2_machine_config_v2.cluster_template_ec2.name
      }
    }
  }
  kubernetes_version = var.workload_kubernetes_version
}

resource "null_resource" "wait_for_cluster_readiness" {
  depends_on = [rancher2_cluster_v2.cluster]

  triggers = {
    provisioning_cluster_id = rancher2_cluster_v2.cluster.id
    management_cluster_id   = rancher2_cluster_v2.cluster.cluster_v1_id
    rancher_api_url         = var.rancher_api_url
    insecure                = tostring(var.rancher_insecure)
    timeout                 = var.cluster_ready_wait_duration
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      RANCHER_URL             = var.rancher_api_url
      RANCHER_TOKEN           = var.rancher_api_token
      PROVISIONING_CLUSTER_ID = rancher2_cluster_v2.cluster.id
      MANAGEMENT_CLUSTER_ID   = rancher2_cluster_v2.cluster.cluster_v1_id
      RANCHER_INSECURE        = tostring(var.rancher_insecure)
      TIMEOUT_DURATION        = var.cluster_ready_wait_duration
    }

    command = "/bin/bash ${path.root}/../../../tools/scripts/wait-for-rancher-cluster.sh"
  }
}

# Create a new rancher2 Node Template
resource "rancher2_machine_config_v2" "cluster_template_ec2" {
  generate_name = "${var.workload_cluster_name}-"

  amazonec2_config {
    ami            = data.aws_ami.ubuntu.id
    instance_type  = var.instance_type
    region         = var.aws_region
    subnet_id      = var.aws_subnet_id
    root_size      = 16
    security_group = [var.ec2_security_group_name]
    vpc_id         = var.aws_vpc_id
    zone           = local.aws_zone_suffix
  }
}