# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "node" {
  count       = var.cloud_credential_id != null && trimspace(var.cloud_credential_id) != "" ? 0 : 1
  name        = "${var.workload_cluster_name}-node"
  description = "Terraform-managed cloud credential for example infrastructure"

  amazonec2_credential_config {
    access_key = var.access_key
    secret_key = var.secret_key
  }
}

resource "rancher2_cluster_v2" "cluster" {
  name                  = var.workload_cluster_name
  enable_network_policy = false

  rke_config {
    machine_global_config = yamlencode({
      cni                 = local.rke_network_plugin
      disable             = ["rke2-ingress-nginx"]
      ingress-controller  = "traefik"
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

resource "terraform_data" "wait_for_cluster_readiness" {
  depends_on = [rancher2_cluster_v2.cluster]

  triggers_replace = {
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

    command = "/bin/bash ${path.module}/../../../tools/scripts/wait-for-rancher-cluster.sh"
  }
}

resource "terraform_data" "fix_cluster_ec2_imds" {
  count      = var.enable_cluster_scoped_imds_fix ? 1 : 0
  depends_on = [terraform_data.wait_for_cluster_readiness]

  triggers_replace = {
    aws_region          = var.aws_region
    instance_ids        = var.enable_cluster_scoped_imds_fix ? join(",", sort(data.aws_instances.downstream_nodes[0].ids)) : ""
    http_endpoint       = "enabled"
    http_tokens         = "required"
    hop_limit           = "2"
    cluster_tag_key     = "tf-aws-platform-cluster"
    cluster_tag_value   = var.workload_cluster_name
    component_tag_key   = "tf-aws-platform-component"
    component_tag_value = "downstream-rke2"
    managed_tag_key     = "tf-aws-platform-managed"
    managed_tag_value   = "true"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      AWS_REGION                  = var.aws_region
      CLUSTER_TAG_KEY             = "tf-aws-platform-cluster"
      CLUSTER_TAG_VALUE           = var.workload_cluster_name
      COMPONENT_TAG_KEY           = "tf-aws-platform-component"
      COMPONENT_TAG_VALUE         = "downstream-rke2"
      MANAGED_TAG_KEY             = "tf-aws-platform-managed"
      MANAGED_TAG_VALUE           = "true"
      HTTP_ENDPOINT               = "enabled"
      HTTP_TOKENS                 = "required"
      HTTP_PUT_RESPONSE_HOP_LIMIT = "2"
    }

    command = "/bin/bash ${path.module}/../../../tools/scripts/fix-downstream-ec2-imds.sh"
  }
}

# Create a new rancher2 Node Template
resource "rancher2_machine_config_v2" "cluster_template_ec2" {
  generate_name = "${var.workload_cluster_name}-"

  amazonec2_config {
    ami                  = data.aws_ami.ubuntu.id
    http_endpoint        = "enabled"
    http_tokens          = "required"
    instance_type        = var.instance_type
    region               = var.aws_region
    subnet_id            = var.aws_subnet_id
    root_size            = 16
    security_group       = [var.ec2_security_group_name]
    tags                 = local.downstream_ec2_tags_csv
    vpc_id               = var.aws_vpc_id
    zone                 = local.aws_zone_suffix
    iam_instance_profile = var.downstream_node_instance_profile_name
  }
}