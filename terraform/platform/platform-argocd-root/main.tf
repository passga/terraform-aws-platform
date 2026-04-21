module "k8s_argocd" {
  source = "../../modules/k8s-argocd"

  namespace            = var.namespace
  argocd_chart_version = var.argocd_chart_version
  hostname             = var.argocd_hostname
  cluster_issuer_name  = data.terraform_remote_state.platform_issuer.outputs.cluster_issuer_name
  ingress_class_name   = var.ingress_class_name
  tls_secret_name      = var.tls_secret_name
}
