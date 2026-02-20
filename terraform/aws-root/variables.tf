variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "eu-west-3"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone"
  default     = "eu-west-3a"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "perf"
}


variable "ssh_key_name" {
  type        = string
  description = "Name of the AWS EC2 key pair to attach to the instance"
}

variable "ssh_private_key" {
  type        = string
  description = "Path where the AWS EC2 key is located "
}

variable "admin_cidr" {
  type        = string
  description = "Admin IP or CIDR allowed to access SSH/HTTPS/K8s API (e.g. 1.2.3.4 or 1.2.3.4/32)"
}

variable "allow_http_01" {
  type        = bool
  description = "Allow inbound HTTP (80) for Let's Encrypt HTTP-01 challenge. Required if Rancher uses letsEncrypt tls.source."
  default     = true
}

variable "http_01_cidr" {
  type        = string
  description = "CIDR allowed to reach port 80. Use 0.0.0.0/0 for Let's Encrypt."
  default     = "0.0.0.0/0"
}

variable "k3s_version" {
  type        = string
  description = "k3s version to install"
  default     = "v1.29.4+k3s1"
}

locals {
  admin_cidr_norm = can(cidrnetmask(var.admin_cidr)) ? var.admin_cidr : "${var.admin_cidr}/32"
}


