variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by the Kubernetes/Helm providers."
}


variable "letsencrypt_environment" {
  type        = string
  description = "Let's Encrypt environment: staging or production."
  default     = "production"
  validation {
    condition     = contains(["staging", "production"], var.letsencrypt_environment)
    error_message = "letsencrypt_environment must be 'staging' or 'production'."
  }
}

variable "letsencrypt_email" {
  type        = string
  description = "Email used by Let's Encrypt to issue the Rancher TLS certificate."
  default     = "you@example.com"
}
