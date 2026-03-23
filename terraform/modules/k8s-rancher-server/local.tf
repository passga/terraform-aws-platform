locals {
  # Accept either a bare hostname (recommended) or a full URL.
  rancher_api_url = startswith(var.rancher_hostname, "http") ? var.rancher_hostname : "https://${var.rancher_hostname}"
}
