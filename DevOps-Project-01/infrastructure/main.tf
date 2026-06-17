# Main terraform configuration file for the AWS infrastructure setup.

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

# Importing the VPC module
module "vpc" {
  source = "./modules/vpc"

  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.aviailability_zones
}

# Security Module
module "security" {
  source = "./modules/security"

  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = var.allowed_ssh_cidr_blocks
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment = var.environment
  subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids = [
  module.security.db_security_group_id]
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# Application Load Balancer Module 
module "alb" {
  source = "./modules/alb"

  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
}

#Auto Scaling Group Module
module "asg" {
  source = "./modules/asg"

  environment = var.environment
  #vpc_id      = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids = [module.security.app_security_group_id]
  target_group_arns = [module.alb.target_group_arn]
  instance_type    = var.instance_type
  key_name         = var.key_name
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
}

# CloudWatch Module
module "monitoring" {
  source = "./modules/monitoting"

  environment     = var.environment
  rds_instance_id = module.rds.db_instance_id
  asg_name        = module.autoscaling.asg_name
}