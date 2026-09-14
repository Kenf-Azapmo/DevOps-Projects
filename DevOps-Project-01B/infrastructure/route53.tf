/*

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.environment}-hosted-zone"
    Environment = var.environment
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = true
  }

}

*/