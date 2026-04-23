variable "aws_region" {
  type = string
}

variable "aws_zone" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

variable "ec2_security_group_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "access_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "secret_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "cloud_credential_id" {
  type        = string
  description = "Existing Rancher cloud credential secret name/id to reuse instead of creating a new one."
  default     = null
  nullable    = true
}

variable "control_plane_quantity" {
  type    = number
  default = 1

  validation {
    condition     = var.control_plane_quantity >= 1
    error_message = "control_plane_quantity must be at least 1"
  }
}

variable "worker_quantity" {
  type    = number
  default = 1

  validation {
    condition     = var.worker_quantity >= 0
    error_message = "worker_quantity must be greater than or equal to 0"
  }
}

variable "cluster_ready_wait_duration" {
  type        = string
  description = "Time to wait for the downstream Rancher cluster to become ready."
  default     = "600s"
}

variable "workload_cluster_name" {
  type        = string
  description = "Name of the workload cluster"

  validation {
    condition     = length(var.workload_cluster_name) > 0
    error_message = "cluster name cannot be empty"
  }
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version used for the cluster"
}

variable "windows_prefered_cluster" {
  type        = bool
  description = "Enable windows support for the cluster"
  default     = false
}

variable "prefix" {
  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.prefix)) > 0
    error_message = "prefix cannot be empty"
  }
}

variable "rancher_api_url" {
  type        = string
  description = "Rancher API base URL used to poll downstream cluster readiness."
}

variable "rancher_api_token" {
  type        = string
  description = "Rancher API token used to poll downstream cluster readiness."
  sensitive   = true
}

variable "rancher_insecure" {
  type        = bool
  description = "Allow insecure TLS when polling the Rancher API."
  default     = false
}

variable "downstream_node_instance_profile_name" {
  type        = string
  description = "AWS IAM Instance Profile name attached to downstream RKE2 EC2 nodes."
}

locals {
  using_existing_cloud_credential = var.cloud_credential_id != null && trimspace(var.cloud_credential_id) != ""
  using_supplied_aws_keys         = var.access_key != null && trimspace(var.access_key) != "" && var.secret_key != null && trimspace(var.secret_key) != ""
}

check "cloud_credential_configuration" {
  assert {
    condition     = local.using_existing_cloud_credential || local.using_supplied_aws_keys
    error_message = "Set cloud_credential_id or provide both access_key and secret_key."
  }
}
