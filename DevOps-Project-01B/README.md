# Deploy Java Application on AWS 3-Tier Architecture	
    Architecture diagram: docs/architecture.png (add the diagram file to the repo under this path so the link below resolves)
    
# link to my diagram .......................

## Table of Content 
    
1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Pre-Requisites](#pre-requisites)
4. [Infrastructure Setup](#infrastructure-setup)
   - [VPC and Networking](#vpc-and-networking)
   - [Security Configuration](#security-configuration)
   - [Database Layer](#database-layer)
5. [Application Setup](#application-setup)
   - [Build Environment](#build-environment)
   - [Application Deployment](#application-deployment)
   - [Load Balancing and Auto Scaling](#load-balancing-and-auto-scaling)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Security Best Practices](#security-best-practices)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Contributing](#contributing)

---
# link to my qiagrame ......................................................

---

# Project Overview

## Introduction 

This project demonstrates the deployment of a production-grade Java web application using AWS's robust 3-tier architecture highly available across two availability zones. The implementation follows cloud-native best practices, ensuring high availability, scalability, and security across all application tiers.
The infrastructure is managed as code with Terraform, while the application delivery process is automated with GitHub Actions: : Maven build & test → SonarQube code quality scan → Docker image build → push to Amazon ECR → Terraform apply → rolling deploy to the EC2 Auto Scaling Group.

### Key Features

- **High Availability:** Multi-AZ deployment with automated RDS failover
- **Auto Scaling:** Dynamic EC2 capacity based on CPU utilization
- **Security:** Defense-in-depth: per-tier security groups, IAM roles instead of static keys, Secrets Manager for credentials, private subnets for app and data tiers
- **Monitoring:** CloudWatch metrics/alarms, CloudTrail auditing, VPC Flow Logs, SNS alerting
- **Infrastructure as Code:** Terraform with remote state (S3) and native state locking, environment-isolated via dev / stage / prod tfvars

## Architecture Overview

### Infrastructure Components

The architecture separates the environment into:

- **Public tier:** Internet-facing Application Load Balancer and NAT Gateways
- **Private application tier:** EC2 instances (running the app in Docker) managed by an Auto Scaling Group
- **Private database tier:** Amazon RDS for MySQL using Multi-AZ 

1. **Presentation Tier (Frontend)**
    - Amazon Route 53 for DNS management
    - Internet Gateway (IGW) for Internet connectivity
    - Application Load Balancer (ALB) internet-facing, spanning both public subnets
    - HTTP (80) redirects to HTTPS (443); ACM issues and validates the certificate via Route 53 DNS validation
    - HTTPS traffic is forwarded to the private application tier

2. **Application Tier (Backend)**
    - The Java application runs in a Docker container on each EC2 instance, built from the Java-Login-App Maven project and pushed to Amazon ECR
    - EC2 instances run in an Auto Scaling Group, deployed exclusively in the private application subnets
    - Instances are distributed across both Availability Zones
    - The ALB performs health checks and distributes traffic across healthy instances only
    - AWS Systems Manager Session Manager provides administrative access — there is no bastion host and no SSH into these instances
    - EC2 instances use an IAM instance role (ECR read-only, CloudWatch agent, SSM, Secrets Manager read) instead of embedded AWS credentials

3. **Data Tier**
    - Amazon RDS for MySQL, Multi-AZ
    - Primary database in Availability Zone A, standby in Availability Zone B
    - Synchronous replication between primary and standby, with automatic failover
    - Master credentials are managed by RDS and stored in AWS Secrets Manager (manage_master_user_password) — never hardcoded in application config
    - Automated backups and point-in-time recovery
    - Not publicly accessible; reachable only from the application security group on port 3306

4. **Supporting AWS Services**
    - **Amazon ECR:** Docker image registry for the application
    - **Amazon S3:** Terraform remote state, CloudTrail logs, application/log artifacts
    - **AWS Secrets Manager:** RDS master credentials
    - **Amazon CloudWatch:** metrics, alarms, log groups (application, system, docker, VPC flow logs)
    - **AWS CloudTrail:** multi-region API auditing, stored in S3
    - **VPC Flow Logs:** network traffic visibility, sent to CloudWatch Logs
    - **Amazon SNS:** email alerting on CloudWatch alarms
    - **AWS IAM:** identity and access management, including a GitHub OIDC role for the CI/CD pipeline (no long-lived AWS keys in GitHub)

### Network Architecture
**VPC Design**
- One VPC per environment, 10.<env-index>.0.0/16
    + dev → 10.0.0.0/16
    + stage → 10.1.0.0/16
    + prod → 10.2.0.0/16
- Each VPC spans two Availability Zones with three subnet tiers: public, private-app, private-db
- One NAT Gateway per Availability Zone (in each public subnet), so each private app subnet routes outbound traffic through its own AZ's NAT Gateway
- The database subnets have no route to the internet at all

dev subnet layout (see infrastructure/envs/dev.tfvars for the source of truth):
   **Tier**	                            **AZ-A (us-east-1a)**      	**AZ-B (us-east-1b)**
- Public (ALB, NAT Gateway)	               10.0.1.0/24	                10.0.2.0/24
- Private application (EC2 ASG)	           10.0.11.0/24  	            10.0.12.0/24
- Private database (RDS)	               10.0.21.0/24	                10.0.22.0/24
stage and prod follow the same pattern with 10.1.x.x and 10.2.x.x respectively — see infrastructure/envs/stage.tfvars and infrastructure/envs/prod.tfvars.

# Pre-Requisites

## Required Accounts and Tools

### 1. AWS Account Setup
- Create an [AWS Free Tier Account](https://aws.amazon.com/free/)
- Install AWS CLI v2
```bash
  # For Linux
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install

  # For macOS
  brew install awscli

  # Configure AWS CLI
  aws configure

  # Verify installation
  aws --version
```
- Install Terraform >= 1.10.0 (required for native S3 state locking — see State Management)

### 2. Development Tools
- **Git**: Version control system
```bash
  # For Linux
  sudo apt-get update
  sudo apt-get install git

  # For macOS
  brew install git

  # Verify installation
  git --version
```
- Docker — required to build and test the application image locally
- Java 11 + Maven — required to build the Java-Login-App project locally

### 3. CI/CD Integration
**SonarQube/SonarCloud account**
  - Sign up at [SonarCloud](https://sonarcloud.io/) (or point at your self-hosted SonarQube server)
  - Generate authentication token and store it in GitHub Acation secret (SONAR_TOKEN)
  - Configure project settings in Java-login-App/pom.xml:   
```bash
    # Add to pom.xml
    <properties>
        <sonar.projectKey>your_project_key</sonar.projectKey>
        <sonar.organization>your_organization</sonar.organization>
        <sonar.host.url>https://sonarcloud.io</sonar.host.url>
    </properties>
```
The pipeline pushes Docker images directly to Amazon ECR (provisioned by infrastructure/ecr.tf) — no separate artifact repository (e.g. JFrog) is required.

# Infrastructure Setup
    The architecture uses a per-environment VPC with public, private application, and private database subnet tiers distributed across two Availability Zones. All infrastructure is provisioned with Terraform from the infrastructure/ directory — the AWS CLI commands below are shown for clarity on what Terraform creates, not as a manual setup path.

## State Management

    Before provisioning any environment, the Terraform remote state backend must be bootstrapped once per environment:
```bash
    cd infrastructure/bootstrap
    terraform init
    terraform apply -var="environment=dev" -var="aws_region=us-east-1"
```
This creates a versioned, encrypted, private S3 bucket (<env>-terraform-state-<account-id>) to hold that environment's state. State locking is handled natively by S3 (Terraform >= 1.10's use_lockfile backend option in infrastructure/version.tf) — a separate DynamoDB lock table is not used in this project.

Then generate the backend config and initialize the main configuration:
```bash
    cd infrastructure
    ./scripts/generate-backend-configs.sh dev
    terraform init -backend-config=envs/dev-backend.hcl
```

## VPC and Networking

# VPC Creation
Terraform (infrastructure/vpc.tf) creates one VPC per environment with DNS support and DNS hostnames enabled:

```bash
    # Equivalent AWS CLI (dev environment)
    aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=dev-vpc}]' \
        --region us-east-1
```
### 2. Subnet Configuration
The VPC is divided into public, private-application, and private-database subnets across two Availability Zones (see the Network Architecture table above for the full CIDR layout).
```bash
    # Public Subnet A (AZ-A)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.1.0/24 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-public-subnet-1}]'

    # Public Subnet B (AZ-B)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.2.0/24 \
        --availability-zone us-east-1b \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-public-subnet-2}]'

    # Private Application Subnet A (AZ-A)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.11.0/24 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-app-subnet-1}]'

    # Private Application Subnet B (AZ-B)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.12.0/24 \
        --availability-zone us-east-1b \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-app-subnet-2}]'

    # Private Database Subnet A (AZ-A)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.21.0/24 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-db-subnet-1}]'

    # Private Database Subnet B (AZ-B)
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 10.0.22.0/24 \
        --availability-zone us-east-1b \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-db-subnet-2}]'
```
The public subnets host the internet-facing ALB and the NAT Gateways. The private application subnets host the EC2 instances managed by the Auto Scaling Group. The private database subnets host the RDS Multi-AZ instance and have no outbound internet route at all.

# Availability Zones
```bash
    availability_zones = [
    "us-east-1a",
    "us-east-1b"
    ]
```

The subnet at index 0 is placed in us-east-1a, and the subnet at index 1 in us-east-1b, for every tier.

### 3. Gateway Setup
```bash
    # Create and attach Internet Gateway
    aws ec2 create-internet-gateway \
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=dev-igw}]'

    aws ec2 attach-internet-gateway \
        --vpc-id vpc-xxx \
        --internet-gateway-id igw-xxx

    # One Elastic IP + NAT Gateway per public subnet (per AZ)
    aws ec2 allocate-address --domain vpc
    aws ec2 create-nat-gateway \
        --subnet-id subnet-public-1 \
        --allocation-id eipalloc-xxx \
        --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=dev-nat-gateway-1}]'

    aws ec2 allocate-address --domain vpc
    aws ec2 create-nat-gateway \
        --subnet-id subnet-public-2 \
        --allocation-id eipalloc-yyy \
        --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=dev-nat-gateway-2}]'
```

Each private application subnet routes its outbound traffic through the NAT Gateway in its own Availability Zone (AZ-A's app subnet → NAT Gateway A; AZ-B's app subnet → NAT Gateway B), keeping outbound traffic within the same AZ where possible.

### 4. Route Table Configuration
The public subnets use a public route table with the Internet Gateway as the default route.

Each private subnet has its own route table and routes internet-bound traffic through its corresponding NAT Gateway.

    **Route table**                       **Destination**         	**Target**
- Public (shared, AZ-A & AZ-B)	            0.0.0.0/0	        Internet Gateway
- Private App — AZ-A                	    0.0.0.0/0	        NAT Gateway A
- Private App — AZ-B	                    0.0.0.0/0	        NAT Gateway B
- Private DB — AZ-A & AZ-B	        	(no default route       no internet access)

### 5. VPC Flow Logs

VPC Flow Logs are enabled to provide visibility into all network traffic within the VPC, delivered to a dedicated CloudWatch Logs group with a 14-day retention period (infrastructure/cloudwatch.tf, infrastructure/vpc_flow_logs.tf):
```bash
    aws ec2 create-flow-logs \
        --resource-type VPC \
        --resource-ids vpc-xxx \
        --traffic-type ALL \
        --log-destination-type cloud-watch-logs \
        --log-group-name vpc/dev/flow-logs \
        --deliver-logs-permission-arn arn:aws:iam::ACCOUNT_ID:role/dev-vpc-flow-logs-role
```

## Security Configuration

### 1. Security Groups

The architecture uses separate security groups for the Application Load Balancer, application servers, and RDS database each with minimum required access

# Create Application Load Balancer security group
```bash
    # ALB security group — allow HTTP/HTTPS from the internet
    aws ec2 create-security-group --group-name ALBSG --description "ALB security group" --vpc-id vpc-xxx
    aws ec2 authorize-security-group-ingress --group-id sg-alb-xxx --protocol tcp --port 80  --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id sg-alb-xxx --protocol tcp --port 443 --cidr 0.0.0.0/0

    # App security group — allow traffic only from the ALB security group, on the app port
    aws ec2 create-security-group --group-name AppSG --description "Application security group" --vpc-id vpc-xxx
    aws ec2 authorize-security-group-ingress --group-id sg-app-xxx --protocol tcp --port 8080 --source-group sg-alb-xxx

    # DB security group — allow MySQL only from the App security group
    aws ec2 create-security-group --group-name DBSG --description "RDS security group" --vpc-id vpc-xxx
    aws ec2 authorize-security-group-ingress --group-id sg-db-xxx --protocol tcp --port 3306 --source-group sg-app-xxx
```
The ALB is the only internet-facing component. Application EC2 instances and the RDS database are never directly reachable from the internet.

### 2. IAM Roles and Policies

- EC2 instances assume an IAM instance role (infrastructure/iam.tf) with read-only ECR access, the CloudWatch agent policy, SSM managed-instance access, and a scoped policy to read the RDS master credential secret — never static AWS access keys.
- GitHub Actions authenticates to AWS via an OIDC federated IAM role (infrastructure/iam_github.tf), issuing short-lived, temporary credentials scoped to a specific repository and branch. No long-lived AWS access keys are stored in GitHub.

```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["s3:GetObject", "s3:PutObject"],
                "Resource": "arn:aws:s3:::your-bucket/*"
            }
        ]
    }
```

## Database Layer

The database layer uses Amazon RDS for MySQL inside the private database subnets, Multi-AZ, with a primary instance in one Availability Zone and a synchronously-replicated standby in the other for automatic failover.

Master credentials are not set via a static password parameter — infrastructure/rds.tf sets manage_master_user_password = true, so RDS generates and rotates the master password through AWS Secrets Manager automatically. The equivalent manual CLI call, if you were creating this by hand, would look like:

### 1. RDS Instance Creation
```bash
    aws rds create-db-instance \
    --db-instance-identifier dev-mysql \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.4 \
    --master-username admin \
    --manage-master-user-password \
    --allocated-storage 20 \
    --multi-az \
    --storage-encrypted \
    --no-publicly-accessible \
    --vpc-security-group-ids sg-db-xxx \
    --db-subnet-group-name dev-mysql-subnet-group
```
The application reads its database credentials from Secrets Manager at container startup (see Containerization) — credentials must never be hardcoded in application.properties or committed to the repository.

### 2. Database Initialization

After the RDS instance becomes available, connect using its private endpoint (from Terraform output rds_endpoint) to create the schema:

```sql
    -- Connect to database

    CREATE DATABASE appdb;
    USE appdb;

     -- Create users table

    CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
    -- Create necessary indexes
    CREATE INDEX idx_username ON users(username);
    CREATE INDEX idx_email ON users(email);
```
The application EC2 instances reach RDS purely over the private network — the database is never assigned a public IP.

# Application Setup

## Build Environment

### 1. Maven Configuration

```xml
<!-- pom.xml -->
<project>
    <properties>
        <java.version>11</java.version>
        <spring.version>2.5.12</spring.version>
    </properties>
    
    <dependencies>
        <!-- Add your dependencies here -->
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

Java-Login-App/pom.xml builds a WAR artifact on Java 11 with Spring Boot 2.7.x:

### 2. Build Process
```bash 
    # Clean and build the project
    mvn clean package -DskipTests

    # Run tests
    mvn test
    
    # Deploy to JFrog   (Incase yiu are using JFrog insted of AWS ECR)
    mvn deploy
```

### 3. Containerization

The application is packaged as a Docker image and pushed to the ECR repository provisioned by infrastructure/ecr.tf (<environment>-app-repo). A Dockerfile builds the WAR with Maven and serves it from a Tomcat base image on the application port (8080 by default, matching var.app_port).

```bash
    docker build -t <environment>-app-repo:<tag> .

    aws ecr get-login-password --region us-east-1 \
        | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

    docker tag <environment>-app-repo:<tag> <account-id>.dkr.ecr.us-east-1.amazonaws.com/<environment>-app-repo:<tag>
    docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/<environment>-app-repo:<tag>
```

## Application Deployment

Each EC2 instance's launch template (infrastructure/ec2.tf) installs Docker, then pulls and runs the application image from ECR, publishing it on var.app_port. There is no Nginx or Tomcat installed directly on the host — the container is the runtime. The ALB target group forwards HTTPS traffic straight to that port on each instance and health-checks app_health_check_path.

New versions are rolled out by updating the image tag referenced in the launch template and triggering an Auto Scaling Group instance refresh (rolling replacement, 50% minimum healthy percentage) — see aws_autoscaling_group.app.instance_refresh in ec2.tf.

## CI/CD Pipeline

See pipelines/pipeline.yml for the GitHub Actions workflow definition and the CI/CD Pipeline diagram panel for the full 8-step flow: code push → GitHub Actions trigger → Maven build & test → SonarQube scan → Docker build → push to ECR → Terraform apply → deploy to the EC2 Auto Scaling Group. Authentication to AWS uses the OIDC federated role described in IAM Roles and Policies — no static AWS credentials are stored as GitHub secrets.

# Monitoring and Maintenance

## CloudWatch Setup

infrastructure/cloudwatch.tf and cloudwatch_agent.tf provision:

- A CloudWatch agent configuration (pushed via SSM Parameter Store) collecting CPU, memory, disk, disk I/O, and network stats from every instance
- Dedicated log groups for application logs, system logs (/var/log/messages, cloud-init output), and Docker container logs
- Alarms — ALB unhealthy host count, ALB 5xx rate, RDS CPU utilization, RDS free storage, ASG CPU utilization — all notifying the <environment>-alerts SNS topic, which emails alert_email


# Security Best Practices
## Network Security
    - Security groups scoped to the minimum required source/port per tier
    - VPC Flow Logs enabled
    - Database subnets have no internet route
## Application Security
    - No SSH access — administrative access is via AWS Systems Manager Session Manager only
    - Regular security patching of the base container image
    - AWS Secrets Manager for all database credentials
## Data Security
    - Encryption at rest (RDS, S3, CloudTrail)
    - TLS termination at the ALB (ACM-issued certificate, DNS-validated via Route 53)
    - Automated RDS backups with a configurable retention period

# Troubleshooting Guide

## Common Issues and Solutions

### 1. Connection Issues
```bash
    # Verify security group rules
    aws ec2 describe-security-groups --group-ids sg-xxx

    # Test load balancer target health
    aws elbv2 describe-target-health --target-group-arn <alb_target_group_arn output>

    # Check connectivity
    telnet database-endpoint 3306
```

### 2. Performance Issues
```bash
    # Check CPU usage
    top -bn1

    # Monitor memory usage
    free -m

    # Check disk usage
    df -h

    # Monitor Tomcat threads
    ps -eLf | grep java | wc -l
```

# Contributing

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Development Setup

```bash
# Clone repository
    git clone https://github.com/Kenf-Azapmo/DevOps-Projects.git

    # Install dependencies / Build Application
    cd DevOps-Project-01B/Java-Login-App
    mvn install

    # Run tests
    mvn test
```
---

## 🛠️ Author & Community

This project is maintained by **[kENFACK AZAPMO](https://github.com/Kenf-Azapmo)** 💡.
Your feedback and contributions are welcome!

📧 **Connect with me:**
- **GitHub**: [@Kenf-Azapmo](https://github.com/Kenf-Azapmo)
- **Whatsapp:** [Whatsapp](wa.me/237690195106)
- **LinkedIn**: [KENFAC AZAPMO Marcelin](linkedin.com/in/kenfack-azapmo-marcelin-67a79b1b6)

---

## ⭐ Support the Project

If you found this project helpful, please consider:
- **Starring** ⭐ the repository
- **Sharing** it with your network
- **Contributing** to its improvement

### 📢 Stay Connected

![Follow Me](https://imgur.com/2j7GSPs.png) .......................

> [!Important]
> This documentation is continuously evolving. For the latest updates, please check the repository regularly.