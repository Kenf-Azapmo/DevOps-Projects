# AWS Infrastructure for Java Application

This directory contains Terraform configurations to set up the AWS infrastructure for the Java application deployment. The infrastructure follows AWS best practices and implements a secure, scalable, and highly available architecture.

## Architecture Overview

The infrastructure consists of:

- VPC with public and private subnets across multiple availability zones
- Application Load Balancer (ALB) in public subnets
- EC2 instances in private subnets managed by Auto Scaling Groups
- RDS MySQL database in private subnets
- Bastion host for secure SSH access
- CloudWatch monitoring and logging

## Prerequisites

1. **AWS Account and Credentials**
   - AWS account with appropriate permissions
   - AWS CLI installed and configured
   - Access key and secret key with necessary permissions

2. **Tools**
   - Terraform >= 1.0.0
   - AWS CLI >= 2.0.0

## Directory Structure

```
infrastructure/
|
│   ├── acm.tf
│   ├── alb.tf
│   ├── cloudtrail.tf
│   ├── cloudwatch.tf
│   ├── cloudwatch_agent.tf
│   ├── ec2.tf
│   ├── ecr.tf
│   ├── iam.tf
│   ├── iam_github.tf 
|   ├──Infrastructure.tf # This file
│   ├── outputs.tf
│   ├── rds.tf
│   ├── route53.tf
│   ├── security.tf
│   ├── sns.tf
│   ├── variables.tf
│   ├── version.tf
│   ├── vpc.tf
│   ├── vpc_flow_logs.tf
│   ├── terraform.tfvars
│   ├── envs/  # Environment-specific configurations (optional)
|   |    ├── dev/
│   |    ├── stage/
│   |    └── prod/
|   |
│   └── bootstrap/
|   |    ├── main.tf
│   |    ├── outputs.tf
|   |    ├── variables.tf
|   |    └── version.tf
│       
│
└── pipelines/
    └── pipeline.yml

```

## Usage

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Configure Variables**
   Create a `terraform.tfvars` file:
   ```hcl
   aws_region         = "us-east-1"
   environment        = "dev"
   vpc_cidr           = "192.168.0.0/16"
   public_subnets     = ["192.168.1.0/24", "192.168.2.0/24"]
   app_subnets        = ["192.168.3.0/24", "192.168.4.0/24"]
   db_subnets         = ["192.168.5.0/24", "192.168.6.0/24"]
   availability_zones = ["us-east-1a", "us-east-1b"]

   app_port             = 8080
   instance_type        = "t3.micro"
   asg_min_size         = 2
   asg_desired_capacity = 2
   asg_max_size         = 4

   db_name                    = "appdb"
   db_username                = "admin"
   db_instance_class          = "db.t3.micro"
   db_allocated_storage       = 20
   db_max_allocated_storage   = 50
   db_backup_retention_period = 1
   db_backup_window           = "03:00-04:00"
   db_maintenance_window      = "Sun:04:00-Sun:05:00"

   app_health_check_path = "/"

   db_engine_version      = "8.4"
   db_deletion_protection = false
   db_skip_final_snapshot = true

   domain_name = "your_domain_name.com"  

   alert_email = "youaddressegmail.com"


   github_repository = "https://github.com/github repository"
   github_branch     = "main"
   ```

3. **Plan the Infrastructure**
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply the Infrastructure**
   ```bash
   terraform apply tfplan
   ```

## Module Outputs

### VPC Module Outputs

The VPC module provides the following outputs for integration with other modules:

**Basic Resources:**
- `vpc_id` - ID of the VPC
- `vpc_name` - Name of the VPC (from tags)
- `vpc_cidr_block` - CIDR block of the VPC

**Subnets:**
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `public_subnet_cidrs` - List of public subnet CIDR blocks
- `private_subnet_cidrs` - List of private subnet CIDR blocks

**Networking Components:**
- `internet_gateway_id` - ID of the Internet Gateway
- `public_route_table_ids` - List of public route table IDs
- `private_route_table_ids` - List of private route table IDs

**NAT Gateways:**
- `nat_gateway_ids` - List of NAT Gateway IDs
- `nat_gateway_elastic_ips` - List of Elastic IP addresses associated with NAT Gateways

**Usage Example:**
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ... variables
}

# Access outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}
```

## Security Considerations

1. **Network Security**
   - Each layer of our three tier architecture has its own security group
   - The database subnet does not have access to the internet ........
   - All application servers are in private subnets
   - Only the ALB is exposed to the internet
   - No SSH ..............

2. **Database Security**
   - RDS instance in private subnet
   - Access restricted to application servers
   - Automated backups enabled

3. **Access Management**
   - IAM roles for EC2 instances
   - Security groups with minimal required access
   - VPC flow logs enabled

## Monitoring and Logging

1. **CloudWatch Metrics**
   - CPU utilization
   - Memory usage
   - Network traffic
   - Database connections

2. **CloudWatch Logs**
   - Application logs
   - VPC flow logs
   - Load balancer access logs

## Cost Optimization

1. **Resource Sizing**
   - Right-sized instances based on workload
   - Auto Scaling for optimal resource utilization

2. **Storage Management**
   - Automated cleanup of old logs
   - Lifecycle policies for backups

## Maintenance

1. **Backup Strategy**
   - Automated RDS backups
   - Retention period configurable
   - Point-in-time recovery enabled

2. **Updates and Patches**
   - Use AWS Systems Manager for updates
   - Automated security patches
   - Rolling updates for zero downtime

## Troubleshooting

1. **Common Issues**
   - Check security group rules
   - Verify subnet configurations
   - Review CloudWatch logs

2. **Support**
   - Create GitHub issues for bugs
   - Contact maintainers for critical issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 