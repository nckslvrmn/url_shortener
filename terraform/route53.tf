resource "aws_route53_record" "secret" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    name                   = aws_api_gateway_domain_name.url_shortener.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.url_shortener.regional_zone_id
    evaluate_target_health = false
  }
}
