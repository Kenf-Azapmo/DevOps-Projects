variable "aws_region" {
  description = "AWS region where the Terraform state bucket will be created"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}