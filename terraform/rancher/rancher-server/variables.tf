# Variables for AWS infrastructure module


variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.21.4+k3s1"
}


variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.5.3"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: v0.0.0)"
  default     = "v2.9.2"
}

# Required
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap"
}

# Required
variable "add_windows_node" {
  type        = bool
  description = "Add a windows node to the workload cluster"
  default     = false
}

# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
}
# Variables for rancher common module

# Required
variable "node_public_ip" {
  type        = string
  description = "Public IP of compute node for Rancher cluster"
}

variable "node_internal_ip" {
  type        = string
  description = "Internal IP of compute node for Rancher cluster"
  default     = ""
}

# Required
variable "node_username" {
  type        = string
  description = "Username used for SSH access to the Rancher server cluster node"
}

# Required
variable "ssh_private_key_pem" {
  type        = string
  description = "Private key used for SSH access to the Rancher server cluster node"
}

# Required
variable "rancher_server_dns" {
  type        = string
  description = "DNS host name of the Rancher server"
}

variable "windows_prefered_cluster" {
  type        = bool
  description = "Activate windows supports for the custom workload cluster"
  default     = false
}

variable "prefix" {
  type = string
  default = "perf"
}



variable "kubeconfig_context" {
  type        = string
  description = "Context kubeconfig à utiliser"
  default     = null
}

variable "kubeconfig_path" { type = string }
variable "rancher_hostname" { type = string }
