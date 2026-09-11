terraform {
  required_version = ">= 1.10.0"


  backend "s3" {
    bucket       = "dev-terraform-state-630013977137"
    key          = "dev-terraform-state/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.57"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "Java-Application"
    }

  }

}