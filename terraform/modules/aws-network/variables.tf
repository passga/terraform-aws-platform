variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "demo"
}

variable "admin_cidr" {
  type        = string
  description = "Admin IP or CIDR allowed to access SSH/HTTPS/K8s API (e.g. 1.2.3.4 or 1.2.3.4/32)"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone"
  default     = "eu-west-3a"
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

locals {
  admin_cidr_norm = can(cidrnetmask(var.admin_cidr)) ? var.admin_cidr : "${var.admin_cidr}/32"
}
