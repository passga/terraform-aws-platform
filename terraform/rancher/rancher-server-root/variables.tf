variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by the Kubernetes/Helm providers."
}


variable "rancher_hostname" {
  type        = string
  description = "Rancher hostname (e.g. rancher.<EIP>.nip.io). Do not include the scheme."
}

variable "rancher_version" {
  type        = string
  description = "Rancher Helm chart version (e.g. v2.14.0)."
  default     = "v2.14.0"
}


variable "rancher_bootstrap_insecure" {
  type        = bool
  description = "Allow insecure TLS only for readiness/bootstrap checks."
  default     = false
}

variable "rancher_bootstrap_wait_timeout" {
  type        = string
  description = "Timeout used while waiting for Rancher TLS and API readiness."
  default     = "20m"
}
