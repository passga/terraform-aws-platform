# Variables for rancher common module

# Required
### AWS EC2 instance for creating a single node workload cluster
variable "ec2_security_group_name" {
  type = string
}
variable "ec2_keypair" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "secret_key" {
  type = string
  sensitive = true
}

variable "dockerurl" {
  default = "https://releases.rancher.com/install-docker/19.03.sh"
}

variable "access_key" {
  type = string
  sensitive = true
}


variable "aws_region" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}
# Required
variable "username" {
  type        = string
  description = "Username used for SSH access to the Rancher server cluster node"
}

# Rancher2 administration provider
# Required
variable "rancher_server_token" {
  type = string
}

variable "prefix" {
  type    = string
  default = ""
}

# Required
variable "rancher_server_dns" {
  type        = string
  description = "DNS host name of the Rancher server"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.22.5-rancher1-1"
}

# Required
variable "workload_cluster_name" {
  type        = string
  description = "Name for created custom workload cluster"
}

variable "windows_prefered_cluster" {
  type        = bool
  description = "Activate windows supports for the custom workload cluster"
  default     = false
}

variable "aws_zone" {
  type        = string
  description = "aws zone"
}

variable "instance_type" {
  type = string
}
variable "docker_version" {
  type = string
}
