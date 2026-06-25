/*
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
} */

output "vpc_name" {
  description = "Name of the VPC"
  value       = aws_vpc.main.tags["Name"]
}

/*
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
*/
/*
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
} */

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_ids" {
  description = "list of public route table IDs"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "list of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

# VPC

output "nat_gateway_public_ip" {
  description = "List of NAT Gateway public IP addresses associated with the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# security

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.name.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

/*
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}
*/
output "alb_sg_id" {
  value = aws_security_group.alb.id
}


# RDS 
/*
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
} */

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}


# Bastion 

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "asg_instance_private_ips" {
  value = data.aws_instances.app.private_ips
}

# ASG 

/*
output "asg_name" {
  description = "Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}  */

# ALB

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}
/*
output "target_group_arns"{
  description = "ALB DNS name"
  value = aws_lb_target_group.main.arn
} */