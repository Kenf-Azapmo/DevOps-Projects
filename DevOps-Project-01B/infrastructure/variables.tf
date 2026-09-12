variable "aws_region" {
  description = "AWS Region to be deploy resources"
  type        = string
}

variable "environment" {
  description = "Deployment Environment name (e.g dev, staging, prod)"
  type        = string
}

# VPC 
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "app_subnets" {
  description = "List of private subnet CIDR blocks for the App EC2 instances (ASG)"
  type        = list(string)
}

variable "db_subnets" {
  description = "List of private subnet CIDR blocks for the RDS instances"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources"
  type        = list(string)
}

# EC2 Instances

variable "app_port" {
  description = "Port used by the application"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
}


# RDS 
variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "RDS database username"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
}

variable "db_backup_window" {
  description = "RDS backup window in UTC time (hh:mm-hh:mm)"
  type        = string
}

variable "db_maintenance_window" {
  description = "RDS maintenance window in UTC time (ddd:hh:mm-ddd:hh:mm)"
  type        = string
}



# Route 53 
variable "domain_name" {
  description = "Domain name used by the application"
  type        = string
}








variable "app_health_check_path" {
  description = "HTTP health check path used by the ALB"
  type        = string
  default     = "/actuator/health"
}

variable "db_engine_version" {
  description = "MySQL engine major/minor version"
  type        = string
  default     = "8.4"
}

variable "db_deletion_protection" {
  description = "Whether deletion protection is enabled for RDS"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final RDS snapshot on deletion"
  type    = bool
  default = true
}

# SNS 
variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
}