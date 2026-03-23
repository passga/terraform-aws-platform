variable "project_name" {
  type        = string
  description = "Rancher project name created after the downstream cluster is ready."
}

variable "namespace_name" {
  type        = string
  description = "Rancher namespace name created inside the project."
}

variable "project_description" {
  type        = string
  description = "Description for the Rancher project."
  default     = "Application project created after downstream cluster readiness."
}

variable "namespace_description" {
  type        = string
  description = "Description for the Rancher namespace."
  default     = "Application namespace created after downstream cluster readiness."
}

variable "rancher_insecure" {
  type        = bool
  description = "Allow insecure TLS when calling the Rancher API."
  default     = false
}
