variable "environment" {
  description = "Environment Name"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of Security Group IDs"
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of Target Group ARNs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling group"
  type        = number
}