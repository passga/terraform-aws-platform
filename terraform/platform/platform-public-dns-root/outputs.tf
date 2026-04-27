output "hosted_zone_id" {
  description = "Route53 hosted zone id for the delegated public subdomain."
  value       = aws_route53_zone.public.zone_id
}

output "hosted_zone_name" {
  description = "Route53 hosted zone name for the delegated public subdomain."
  value       = aws_route53_zone.public.name
}

output "hosted_zone_name_servers" {
  description = "Route53 name servers to delegate once from OVH to Route53."
  value       = aws_route53_zone.public.name_servers
}

output "managed_app_records" {
  description = "Managed application DNS records keyed by logical record name."
  value = {
    for name, record in aws_route53_record.app_cname : name => {
      fqdn            = record.fqdn
      target_dns_name = local.normalized_app_records[name].target_dns_name
    }
  }
}
