variable "downstream_node_iam_role_name" {
  type        = string
  description = "Existing IAM role name attached to downstream RKE2 EC2 nodes. AWS Load Balancer Controller permissions are attached to this role."
}

variable "aws_load_balancer_controller_chart_version" {
  type        = string
  description = "Helm chart version for aws-load-balancer-controller."
  default     = "1.14.0"
}
