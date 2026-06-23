variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}
# VPC 
/*
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}  */

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
}

# Security

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production
}

# ALB 
/*
variable "alb_sg_id" {
  description = "Security Group ID for the ALB"
  type        = string
}
*/

# ASG 
/*
variable "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  type        = list(string)
} */

/*
variable "target_group_arns" {
  description = "List of Target Group ARNs"
  type        = list(string)
} */

variable "key_name" {
  description = "Name of the SSH key pair for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the application servers"
  type        = string
}




variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired Capacity for the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Bastion 

variable "ami_id" {
  type = string
}

/*
variable "public_subnet_id" {
  type = string
}
*/
/*
variable "bastion_sg_id" {
  type = string
} */

# RDS 
/*
variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
} */
/*
variable "security_group_ids" {
  description = "List of security group IDs for the RDS instance"
  type        = list(string)
} */

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "javaapp"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}


# Monitoting 
/*
variable "rds_instance_id" {
  description = "The ID of the RDS instance to monitor."
  type        = string
}
 */
/*
variable "asg_name" {
  description = "The name of the Auto Scaling group to monitor."
  type        = string
} */