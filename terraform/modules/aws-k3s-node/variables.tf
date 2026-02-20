
variable "subnet_id" {
  type        = string
  description = "Subnet ID where the k3s node will be deployed"
}

variable "sg_id" {
  type        = string
  description = "Security group ID where the k3s node will be deployed"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the k3s node will be deployed"
}

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
}

variable "k3s_node_instance_type" {
  type        = string
  description = "EC2 instance type for the k3s/Rancher server"
  default     = "t3.medium"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the AWS EC2 key pair to attach to the instance"
}


variable "k3s_version" {
  type        = string
  description = "k3s version to install"
  default     = "v1.29.4+k3s1"
}