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
      cloud-provider-name = "aws"
      disable             = ["rke2-ingress-nginx"]
      ingress-controller  = "traefik"
    })

    # ETCD
    machine_selector_config {
      config = yamlencode({
        kubelet-arg = [
          "cloud-provider=external",
        ]
      })

      machine_label_selector {
        match_labels = {
          "rke.cattle.io/etcd-role" = "true"
        }
      }
    }

    # Control-plane
    machine_selector_config {
      config = yamlencode({
        disable-cloud-controller = true
        kube-controller-manager-arg = [
          "cloud-provider=external",
        ]
        kubelet-arg = [
          "cloud-provider=external",
        ]
      })

      machine_label_selector {
        match_labels = {
          "rke.cattle.io/control-plane-role" = "true"
        }
      }
    }

    # Worker
    machine_selector_config {
      config = yamlencode({
        kubelet-arg = [
          "cloud-provider=external",
        ]
      })

      machine_label_selector {
        match_labels = {
          "rke.cattle.io/worker-role" = "true"
        }
      }
    }

    additional_manifest = <<-EOT
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: aws-cloud-controller-manager
  namespace: kube-system
spec:
  chart: aws-cloud-controller-manager
  repo: https://kubernetes.github.io/cloud-provider-aws
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    hostNetworking: true
    tolerations:
      - key: node.cloudprovider.kubernetes.io/uninitialized
        operator: Equal
        value: "true"
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/etcd
        operator: Exists
        effect: NoExecute
    nodeSelector:
      node-role.kubernetes.io/control-plane: "true"
    args:
      - --configure-cloud-routes=false
      - --use-service-account-credentials=true
      - --v=2
      - --cloud-provider=aws
    clusterRoleRules:
      - apiGroups:
          - ""
        resources:
          - events
        verbs:
          - create
          - patch
          - update
      - apiGroups:
          - ""
        resources:
          - nodes
        verbs:
          - "*"
      - apiGroups:
          - ""
        resources:
          - nodes/status
        verbs:
          - patch
      - apiGroups:
          - ""
        resources:
          - services
        verbs:
          - list
          - patch
          - update
          - watch
      - apiGroups:
          - ""
        resources:
          - services/status
        verbs:
          - list
          - patch
          - update
          - watch
      - apiGroups:
          - ""
        resources:
          - serviceaccounts
        verbs:
          - create
          - get
      - apiGroups:
          - ""
        resources:
          - persistentvolumes
        verbs:
          - get
          - list
          - update
          - watch
      - apiGroups:
          - ""
        resources:
          - endpoints
        verbs:
          - create
          - get
          - list
          - watch
          - update
      - apiGroups:
          - coordination.k8s.io
        resources:
          - leases
        verbs:
          - create
          - get
          - list
          - watch
          - update
          - patch
      - apiGroups:
          - ""
        resources:
          - serviceaccounts/token
        verbs:
          - create
EOT

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
