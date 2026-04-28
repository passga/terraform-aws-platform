locals {

  le_env  = var.letsencrypt_environment
  le_name = "letsencrypt-${local.le_env}"

  le_server_url = (
    local.le_env == "production"
    ? "https://acme-v02.api.letsencrypt.org/directory"
    : "https://acme-staging-v02.api.letsencrypt.org/directory"
  )
}
