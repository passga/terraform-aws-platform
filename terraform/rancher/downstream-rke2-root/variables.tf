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


variable "instance_type" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "Dedicated AWS region for the downstream RKE2 cluster. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "aws_zone" {
  type        = string
  description = "Dedicated AWS availability zone for the downstream RKE2 cluster. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "aws_vpc_id" {
  type        = string
  description = "Dedicated VPC for the downstream RKE2 cluster. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "aws_subnet_id" {
  type        = string
  description = "Dedicated subnet for the downstream RKE2 cluster. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "ec2_security_group_name" {
  type        = string
  description = "Dedicated security group name for the downstream RKE2 cluster nodes. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "control_plane_quantity" {
  type    = number
  default = 1
}

variable "worker_quantity" {
  type    = number
  default = 1
}

variable "cluster_ready_wait_duration" {
  type    = string
  default = "600s"
}

variable "downstream_node_instance_profile_name" {
  type        = string
  description = "Existing AWS IAM Instance Profile name attached to downstream RKE2 EC2 nodes."
}

variable "rancher_insecure" {
  type    = bool
  default = false
}

variable "workload_cluster_name" {
  type = string

  validation {
    condition     = length(trimspace(var.workload_cluster_name)) > 0
    error_message = "workload_cluster_name cannot be empty"
  }
}

variable "workload_kubernetes_version" {
  type = string
}

variable "windows_prefered_cluster" {
  type    = bool
  default = false
}

variable "prefix" {
  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.prefix)) > 0
    error_message = "prefix cannot be empty"
  }
}

locals {
  using_existing_cloud_credential = var.cloud_credential_id != null && trimspace(var.cloud_credential_id) != ""
  using_supplied_aws_keys         = var.access_key != null && trimspace(var.access_key) != "" && var.secret_key != null && trimspace(var.secret_key) != ""
  using_explicit_aws_network      = var.aws_region != null && trimspace(var.aws_region) != "" && var.aws_zone != null && trimspace(var.aws_zone) != "" && var.aws_vpc_id != null && trimspace(var.aws_vpc_id) != "" && var.aws_subnet_id != null && trimspace(var.aws_subnet_id) != "" && var.ec2_security_group_name != null && trimspace(var.ec2_security_group_name) != ""
  using_partial_aws_network = (
    (var.aws_region != null && trimspace(var.aws_region) != "") ||
    (var.aws_zone != null && trimspace(var.aws_zone) != "") ||
    (var.aws_vpc_id != null && trimspace(var.aws_vpc_id) != "") ||
    (var.aws_subnet_id != null && trimspace(var.aws_subnet_id) != "") ||
    (var.ec2_security_group_name != null && trimspace(var.ec2_security_group_name) != "")
  )
  use_aws_root_remote_state = !local.using_explicit_aws_network
  aws_region                = local.using_explicit_aws_network ? var.aws_region : data.terraform_remote_state.aws_root[0].outputs.aws_region
  aws_zone                  = local.using_explicit_aws_network ? var.aws_zone : data.terraform_remote_state.aws_root[0].outputs.aws_zone
  aws_vpc_id                = local.using_explicit_aws_network ? var.aws_vpc_id : data.terraform_remote_state.aws_root[0].outputs.aws_vpc_id
  aws_subnet_id             = local.using_explicit_aws_network ? var.aws_subnet_id : data.terraform_remote_state.aws_root[0].outputs.aws_subnet_id
  ec2_security_group_name   = local.using_explicit_aws_network ? var.ec2_security_group_name : data.terraform_remote_state.aws_root[0].outputs.ec2_security_group_name
}

check "cloud_credential_configuration" {
  assert {
    condition     = local.using_existing_cloud_credential || local.using_supplied_aws_keys
    error_message = "Set cloud_credential_id or provide both access_key and secret_key."
  }
}

check "aws_network_configuration" {
  assert {
    condition     = local.using_explicit_aws_network || !local.using_partial_aws_network
    error_message = "Set all dedicated AWS network values together (aws_region, aws_zone, aws_vpc_id, aws_subnet_id, ec2_security_group_name) or leave them all unset to use aws-root remote state."
  }
}
