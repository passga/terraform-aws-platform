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
  description = "Rancher Helm chart version (e.g. v2.9.2)."
  default     = "v2.9.2"
}


variable "rancher_bootstrap_insecure" {
  type        = bool
  description = "Allow insecure TLS only for bootstrap when Rancher uses self-signed certs."
  default     = true
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address used for Let's Encrypt ACME registration."
}

variable "letsencrypt_environment" {
  type        = string
  description = "Let's Encrypt environment: staging or production."
  default     = "staging"
  validation {
    condition     = contains(["staging", "production"], var.letsencrypt_environment)
    error_message = "letsencrypt_environment must be 'staging' or 'production'."
  }
}

