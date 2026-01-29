# Variables for AWS infrastructure module

// TODO - use null defaults

# Required
variable "aws_access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
  sensitive = true
}

# Required
variable "aws_secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
  sensitive = true
}

variable "aws_session_token" {
  type        = string
  description = "AWS session token used to create AWS infrastructure"
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "eu-west-3"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone used for volume"
  default     = "eu-west-3a"
}

# Required
variable "rancher_server_dns" {
  description="Rancher server dns"
  type        = string
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "perf"
}

variable "rancher_server_instance_type" {
  type        = string
  description = "Instance type used for rancher server ec2 instances"
  default     = "t3.micro"
}

variable "workload_nodes_instance_type" {
  type        = string
  description = "Instance type used for all workload nodes instances deployed"
  default     = "t3.micro"
}


variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ec2_keypair" {
  description ="Name of pem  attached to all new ec2 instances created"
  type    = string
}

# Required
variable "ssh_private_key_file" {
  type    = string
  description ="Location of pem private file using for all ssh connexion"
}


variable "docker_version" {
  type        = string
  description = "Docker version to install on nodes"
  default     = "19.03"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.21.4+k3s1"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.20.12-rancher1-1"
}

variable "aws_zone" {
  type        = string
  description = "aws zone"
  default     = "a"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.5.3"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: v0.0.0)"
  default     = "v2.6.0"
}

# Required
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap"
}

variable "workload_cluster_name" {
  type        = string
  description = "Cluster name to use for deployment of nodes"
}

# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
}

variable "admin_cidr" {
  type        = string
  description = "Admin IP in CIDR format (e.g. x.x.x.x/32)"
}
