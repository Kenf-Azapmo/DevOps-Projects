output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb_sg.id
}