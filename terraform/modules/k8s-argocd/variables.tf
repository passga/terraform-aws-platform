variable "namespace" {
  type        = string
  description = "Namespace where Argo CD will be installed."
  default     = "argocd"
}

variable "argocd_chart_version" {
  type        = string
  description = "Optional Argo CD Helm chart version."
  default     = null
  nullable    = true
}

variable "hostname" {
  type        = string
  description = "Hostname exposed by the Argo CD ingress."
}

variable "cluster_issuer_name" {
  type        = string
  description = "ClusterIssuer name used by cert-manager to issue the Argo CD ingress certificate."
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClass used to expose Argo CD."
  default     = "traefik"
}

variable "tls_secret_name" {
  type        = string
  description = "TLS secret name used by the Argo CD ingress and certificate."
  default     = "argocd-server-tls"
}
