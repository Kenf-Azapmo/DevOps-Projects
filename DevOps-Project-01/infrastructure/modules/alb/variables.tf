#ALB Module Variables

variable "environment" {
  description = "The environment for which the ALB is being created (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to create the ALB"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnet IDs for the ALB"
  type        = list(string)
}

