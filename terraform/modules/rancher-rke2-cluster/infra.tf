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
    cluster_id        = rancher2_cluster_v2.cluster.id
    rancher_api_url   = var.rancher_api_url
    insecure          = tostring(var.rancher_insecure)
    timeout_duration  = var.cluster_ready_wait_duration
  }

  provisioner "local-exec" {
    environment = {
      RANCHER_API_URL = var.rancher_api_url
      RANCHER_TOKEN   = var.rancher_api_token
      CLUSTER_ID      = rancher2_cluster_v2.cluster.id
      TIMEOUT_SECONDS = trimsuffix(var.cluster_ready_wait_duration, "s")
      CURL_INSECURE   = var.rancher_insecure ? "true" : "false"
    }

    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
set -euo pipefail

curl_args=()
if [ "$${CURL_INSECURE}" = "true" ]; then
  curl_args+=("-k")
fi

for ((i=1; i<=$${TIMEOUT_SECONDS}; i+=10)); do
  response="$$(curl -fsS "$${curl_args[@]}" \
    -H "Authorization: Bearer $${RANCHER_TOKEN}" \
    "$${RANCHER_API_URL}/v3/clusters/$${CLUSTER_ID}")"

  state="$$(printf '%s' "$${response}" | grep -o '"state":"[^"]*"' | head -n1 | cut -d'"' -f4)"

  if [ "$${state}" = "active" ]; then
    echo "Cluster $${CLUSTER_ID} is active"
    exit 0
  fi

  echo "Waiting for cluster $${CLUSTER_ID} to become active, current state: $${state:-unknown}"
  sleep 10
done

echo "Cluster $${CLUSTER_ID} did not become active within $${TIMEOUT_SECONDS}s"
exit 1
EOT
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



# Create a new rancher2 Project
resource "rancher2_project" "init_project" {
  depends_on  = [null_resource.wait_for_cluster_readiness]
  name        = var.prefix
  cluster_id  = rancher2_cluster_v2.cluster.id
  description = "${var.prefix} project for running of performance tests"
}

# Create a new rancher2 Namespace
resource "rancher2_namespace" "init_namespace" {
  name        = var.prefix
  project_id  = rancher2_project.init_project.id
  description = "${var.prefix} namespace for running of performance tests"
}
