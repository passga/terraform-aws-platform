variable "aws_load_balancer_controller_chart_version" {
  type        = string
  description = "Helm chart version for aws-load-balancer-controller."
  default     = "1.14.0"
}

variable "kubeconfig_path_override" {
  type        = string
  description = "Optional kubeconfig path override for downstream cluster access."
  default     = null
  nullable    = true
}
