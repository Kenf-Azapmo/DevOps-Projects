variable "environment" {
  description = "The environment for which the monitoring is being set up (e.g., dev, staging, prod)."
  type        = string
}

variable "rds_instance_id" {
  description = "The ID of the RDS instance to monitor."
  type        = string
}

variable "asg_name" {
  description = "The name of the Auto Scaling group to monitor."
  type        = string
}