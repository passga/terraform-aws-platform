resource "aws_route53_zone" "public" {
  name = trimsuffix(var.hosted_zone_name, ".")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "app_cname" {
  for_each = local.normalized_app_records

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.fqdn
  type    = "CNAME"
  ttl     = 300
  records = [each.value.target_dns_name]
}
