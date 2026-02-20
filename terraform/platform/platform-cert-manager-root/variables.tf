variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by the Kubernetes/Helm providers."
}

variable "cert_manager_version" {
  type        = string
  description = "cert-manager Helm chart version (e.g. 1.5.3)."
  default     = "1.5.3"
}
