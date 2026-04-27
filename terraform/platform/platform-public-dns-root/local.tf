locals {
  using_explicit_aws_region = var.aws_region != null && trimspace(var.aws_region) != ""
  use_aws_root_remote_state = !local.using_explicit_aws_region
  resolved_aws_region       = local.using_explicit_aws_region ? var.aws_region : data.terraform_remote_state.aws_root[0].outputs.aws_region
  default_target_dns_name   = trimsuffix(data.terraform_remote_state.downstream_ingress.outputs.traefik_load_balancer_hostname, ".")

  normalized_app_records = {
    for name, record in var.app_records : name => {
      fqdn            = trimsuffix(record.fqdn, ".")
      target_dns_name = trimsuffix(coalesce(record.target_dns_name, local.default_target_dns_name), ".")
    }
  }
}
