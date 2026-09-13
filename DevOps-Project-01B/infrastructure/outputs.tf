# VPC 
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "availability_zones" {
  description = "The availability zones of the VPC"
  value       = aws_subnet.public[*].availability_zone
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "The IDs of the private db subnets"
  value       = aws_subnet.db[*].id
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# ALB
output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "The ID of the App EC2 instances security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "The ID of the RDS instances security group"
  value       = aws_security_group.db.id
}


# EC2 Instances
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_alb.main.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_alb.main.arn
}

output "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  value       = aws_alb_target_group.app.arn
}

output "auto_scaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "RDS MySQL hostname"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_database_name" {
  description = "RDS MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "rds_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}






output "cloudwatch_application_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.application.name
}

output "vpc_flow_logs_group" {
  description = "CloudWatch log group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket containing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.bucket
}














output "route53_name_servers" {
  description = "Route 53 name servers that must be configured at the domain registrar"
  value       = aws_route53_zone.main.name_servers
}

# Route53
output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "application_domain" {
  description = "Application domain name"
  value       = aws_route53_record.app.fqdn
}