resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${data.terraform_remote_state.downstream_rke2.outputs.cluster_name}-aws-load-balancer-controller"
  policy = file("${path.module}/files/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = var.downstream_node_iam_role_name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
  ]

  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false
  version          = var.aws_load_balancer_controller_chart_version
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600

  set = [
    {
      name  = "clusterName"
      value = data.terraform_remote_state.downstream_rke2.outputs.cluster_name
    },
    {
      name  = "region"
      value = data.terraform_remote_state.downstream_rke2.outputs.aws_region
    },
    {
      name  = "vpcId"
      value = data.terraform_remote_state.downstream_rke2.outputs.aws_vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
  ]
}

resource "kubernetes_manifest" "rke2_traefik_service_nlb" {
  depends_on = [helm_release.aws_load_balancer_controller]

  field_manager {
    force_conflicts = true
  }

  computed_fields = [
    "metadata.creationTimestamp",
    "metadata.labels",
    "metadata.resourceVersion",
    "metadata.uid",
    "spec.clusterIP",
    "spec.clusterIPs",
    "spec.healthCheckNodePort",
    "status",
  ]

  manifest = {
    apiVersion = "v1"
    kind       = "Service"

    metadata = {
      name      = data.kubernetes_service_v1.rke2_traefik.metadata[0].name
      namespace = data.kubernetes_service_v1.rke2_traefik.metadata[0].namespace
      annotations = merge(
        try(data.kubernetes_service_v1.rke2_traefik.metadata[0].annotations, {}),
        {
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
          "service.beta.kubernetes.io/aws-load-balancer-subnets"         = data.terraform_remote_state.downstream_rke2.outputs.aws_subnet_id
        }
      )
    }

    spec = {
      externalTrafficPolicy = try(data.kubernetes_service_v1.rke2_traefik.spec[0].external_traffic_policy, null)
      internalTrafficPolicy = try(data.kubernetes_service_v1.rke2_traefik.spec[0].internal_traffic_policy, null)
      ipFamilies            = try(data.kubernetes_service_v1.rke2_traefik.spec[0].ip_families, null)
      ipFamilyPolicy        = try(data.kubernetes_service_v1.rke2_traefik.spec[0].ip_family_policy, null)
      loadBalancerClass     = "service.k8s.aws/nlb"
      selector              = data.kubernetes_service_v1.rke2_traefik.spec[0].selector
      sessionAffinity       = data.kubernetes_service_v1.rke2_traefik.spec[0].session_affinity
      type                  = "LoadBalancer"

      ports = [
        for port in data.kubernetes_service_v1.rke2_traefik.spec[0].port : {
          appProtocol = try(port.app_protocol, null)
          name        = try(port.name, null)
          nodePort    = try(port.node_port, null)
          port        = port.port
          protocol    = try(port.protocol, null)
          targetPort  = try(port.target_port, null)
        }
      ]
    }
  }
}
