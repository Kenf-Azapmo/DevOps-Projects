# Deploy Java Application on AWS 3-Tier Architecture	

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

# link to my qiagrame .....................

--- 

# Project Overview

## Introduction 

This project demonstrates the deployment of a production-grade Java web application using AWS's robust 3-tier architecture across two availability zones. The implementation follows cloud-native best practices, ensuring high availability, scalability, and security across all application tiers.
The infrastructure is managed as code with Terraform, while the application delivery process is automated with GitHub Actions.

### Key Features

    - **High Availability**: Multi-AZ deployment with automated failover
    - **Auto Scaling**: Dynamic resource allocation based on demand
    - **Security**: Defense-in-depth approach with multiple security layers
    - **Monitoring**: Comprehensive logging and monitoring setup
    - **Cost Optimization**: Efficient resource utilization and management
    












## Architecture Overview

### Infrastructure Components

The architecture separates the environment into:

    - Public tier — Internet-facing Application Load Balancer and NAT Gateways
    - Private application tier — EC2 instances managed by an Auto Scaling Group
    - Private database tier — Amazon RDS for MySQL using Multi-AZ failover

1. **Presentation Tier (Frontend)**
    - Amazon Route 53 for DNS management
    - Internet Gateway (IGW) for Internet connectivity
    - Application Load Balancer (ALB) deployed across - multiple Availability Zones
    - One logical ALB associated with both public subnets
    - HTTPS/HTTP traffic forwarded to the private application tier

2. **Application Tier (Backend)**
    - Apache Tomcat servers in Auto Scaling Group (Amazon EC2 Auto Scaling Group).
    - EC2 instances deployed exclusively in private application subnets
    - Application instances distributed across multiple Availability Zones
    - ALB performs health checks and distributes incoming traffic across healthy EC2 instances
    - AWS Systems Manager Session Manager provides administrative access without a bastion host
    - EC2 instances use IAM roles instead of embedded AWS credentials

3. **Data Tier**
    - Amazon RDS for MySQL
    - Multi-AZ deployment
    - Primary database in one Availability Zone
    - Standby database in another Availability Zone
    - Synchronous replication between primary and standby
    - Automatic failover
    - Automated backups and point-in-time recovery

4. **Supporting AWS Services**
    - Amazon ECR — Docker image registry
    - Amazon S3 — Terraform remote state and application/log artifacts
    - Amazon DynamoDB — Terraform state locking
    - AWS Secrets Manager — application/database secrets
    - Amazon CloudWatch — metrics, alarms, and application monitoring
    - AWS CloudTrail — API auditing
    - VPC Flow Logs — network traffic visibility
    - AWS IAM — identity and access management

### Network Architecture

 - **VPC Design**
  - One VPCs 192.168.0.0/16
  - Public and private subnets across multiple AZs
  - Transit Gateway for inter-VPC communication

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

### 3. CI/CD Integration
- **SonarCloud Account**
  - Sign up at [SonarCloud](https://sonarcloud.io/)
  - Generate authentication token
  - Configure project settings:   
     ```bash
    # Add to pom.xml
    <properties>
        <sonar.projectKey>your_project_key</sonar.projectKey>
        <sonar.organization>your_organization</sonar.organization>
        <sonar.host.url>https://sonarcloud.io</sonar.host.url>
    </properties>
    ```

- **JFrog Artifactory**
  - Create account on [JFrog Cloud](https://jfrog.com/start-free/)
  - Set up Maven repository
  - Configure authentication:
    ```xml
    <!-- settings.xml -->
    <servers>
        <server>
            <id>jfrog-artifactory</id>
            <username>${env.JFROG_USERNAME}</username>
            <password>${env.JFROG_PASSWORD}</password>
        </server>
    </servers>
    ```

# Infrastructure Setup
    The architecture uses a primary VPC with public, private application, and database subnet tiers distributed across two Availability Zones.

## VPC and Networking

# VPC Creation
The project uses a single VPC distributed across two Availability Zones.

```bash
    aws ec2 create-vpc \
        --cidr-block 192.168.0.0/16 \
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=dev-vpc}]' \
        --region us-east-1
```
DNS support and DNS hostnames are enabled for the VPC to allow AWS resources to communicate using DNS.

### 2. Subnet Configuration
The VPC is divided into public and private application subnets across two Availability Zones.


# Public Subnets

# Create Public Subnet 1 - Availability Zone A
```bash
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 192.168.1.0/24 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-public-subnet-1}]'
```
# Create Public Subnet 2 - Availability Zone B
```bash
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 192.168.2.0/24 \
        --availability-zone us-east-1b \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-public-subnet-2}]'
```
    The public subnets are used by the internet-facing Application Load Balancer and the NAT Gateways.


# Private Application subnet
# Create Private Subnet 1 - Availability Zone A
```bash
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 192.168.3.0/24 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-private-subnet-1}]'
```
    # Create Private Subnet 2 - Availability Zone B
```bash
    aws ec2 create-subnet \
        --vpc-id vpc-xxx \
        --cidr-block 192.168.4.0/24 \
        --availability-zone us-east-1b \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev-private-subnet-2}]'
```
    The private subnets contain the EC2 instances managed by the Auto Scaling Group.

# Availability Zones
```bash
    availability_zones = [
    "us-east-1a",
    "us-east-1b"
    ]
```

The subnet at index 0 is placed in us-east-1a and the subnet at index 1 is placed in us-east-1b.

### 3. Gateway Setup
The architecture uses an Internet Gateway to provide internet connectivity to the public subnets.

# Create and attach Internet Gateway
```bash
    aws ec2 create-internet-gateway \
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=dev-igw}]'
```
# Attach Internet Gateway to VPC
```bash
    aws ec2 attach-internet-gateway \
        --vpc-id vpc-xxx \
        --internet-gateway-id igw-xxx
```
# Allocate Elastic IP for NAT Gateway 1
```bash
    aws ec2 allocate-address \
        --domain vpc
```

# Create NAT Gateway 1
```bash
    aws ec2 create-nat-gateway \
        --subnet-id subnet-public-1 \
        --allocation-id eipalloc-xxx \
        --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=dev-nat-gateway-1}]'
```

# Allocate Elastic IP for NAT Gateway 2
```bash
    aws ec2 allocate-address \
        --domain vpc
```
# Create NAT Gateway 2
```bash
    aws ec2 create-nat-gateway \
        --subnet-id subnet-public-2 \
        --allocation-id eipalloc-yyy \
        --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=dev-nat-gateway-2}]'
```
The NAT Gateways provide outbound internet access for the private application subnets.

### 4. Route Table Configuration
The public subnets use a public route table with the Internet Gateway as the default route.

# Create public route table
```bash
    aws ec2 create-route-table \
        --vpc-id vpc-xxx \
        --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=dev-public-route-table}]'
```
# Create default route to Internet Gateway
```bash
    aws ec2 create-route \
        --route-table-id rtb-public-xxx \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id igw-xxx
```

Each private subnet has its own route table and routes internet-bound traffic through its corresponding NAT Gateway.

Public route:
    Destination: 0.0.0.0/0
    Target:      Internet Gateway

Private Route Table 1
    Destination: 0.0.0.0/0
    Target:      NAT Gateway 1

Private Route Table 2
    Destination: 0.0.0.0/0
    Target:      NAT Gateway 2







### 5. VPC Flow Logs

VPC Flow Logs are enabled to provide visibility into network traffic within the VPC.

# Create CloudWatch Log Group
```bash
aws logs create-log-group \
    --log-group-name /aws/vpc/dev/flow-logs
```
# Create VPC Flow Logs
```bash
aws ec2 create-flow-logs \
    --resource-type VPC \
    --resource-ids vpc-xxx \
    --traffic-type ALL \
    --log-destination-type cloud-watch-logs \
    --log-group-name /aws/vpc/dev/flow-logs \
    --deliver-logs-permission-arn arn:aws:iam::ACCOUNT_ID:role/dev-vpc-flow-logs-role
```
The Terraform configuration sends VPC Flow Logs to CloudWatch Logs and configures a 30-day retention period.








## Security Configuration

### 1. Security Groups
The architecture uses separate security groups for the Application Load Balancer, application servers, and RDS database.

# Create Application Load Balancer security group
```bash
    aws ec2 create-security-group \
        --group-name ALBSG \
        --description "Security group for Application Load Balancer" \
        --vpc-id vpc-xxx
```

# Allow inbound HTTP
```bash
    aws ec2 authorize-security-group-ingress \
        --group-id sg-alb-xxx \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
```
# Allow inbound HTTPS
```bash   
    aws ec2 authorize-security-group-ingress \
        --group-id sg-alb-xxx \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0

    aws ec2 authorize-security-group-ingress \
        --group-id sg-xxx \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0
```
The Application Load Balancer is the only internet-facing application component. EC2 application instances remain inside the private application subnets.






# Create application security group
Application instances are located in the private subnets and receive application traffic through the ALB.

```bash
    aws ec2 create-security-group \
        --group-name AppSG \
        --description "Security group for application servers" \
        --vpc-id vpc-xxx
```
# Allow application traffic only from the ALB security group
```bash
    aws ec2 authorize-security-group-ingress \
        --group-id sg-app-xxx \
        --protocol tcp \
        --port 8080 \
        --source-group sg-alb-xxx
```
    The application security group allows traffic on port 8080 only from the Application Load Balancer security group.







# Create database security group
```bash
    aws ec2 create-security-group \
        --group-name DBSG \
        --description "Security group for RDS database" \
        --vpc-id vpc-xxx
```
# Allow MySQL traffic only from the application security group
```bash
    aws ec2 authorize-security-group-ingress \
        --group-id sg-db-xxx \
        --protocol tcp \
        --port 3306 \
        --source-group sg-app-xxx
```
    The database security group allows MySQL traffic on port 3306 only from the application security group.

### 2. IAM Roles and Policies
EC2 instances use IAM roles instead of storing AWS access keys directly on the servers.

GitHub Actions uses an AWS IAM role through OIDC authentication, allowing the CI/CD pipeline to obtain temporary AWS credentials.

```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject"
                ],
                "Resource": "arn:aws:s3:::your-bucket/*"
            }
        ]
    }
```

## Database Layer
The database layer uses Amazon RDS for MySQL inside private database subnets.

The target architecture uses Multi-AZ deployment, with a primary database instance in one Availability Zone and a standby instance in the second Availability Zone for automatic failover.

### 1. RDS Instance Creation
```bash
    aws rds create-db-instance \
        --db-instance-identifier dev-mysql \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --engine-version 8.0 \
        --master-username admin \
        --master-user-password "YourSecurePassword" \
        --allocated-storage 20 \
        --multi-az \
        --storage-encrypted \
        --no-publicly-accessible \
        --vpc-security-group-ids sg-db-xxx \
        --db-subnet-group-name your-db-subnet-group
```
The database is not publicly accessible.

The database security group only permits MySQL traffic from the application security group on port 3306.

### 2. Database Initialization
After the RDS instance becomes available, connect to the database using its private RDS endpoint.

```sql
    -- Connect to database

    mysql -h your-rds-endpoint -u admin -p

    -- Create application database

    CREATE DATABASE javaapp;

    USE javaapp;

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
The application EC2 instances connect to the RDS database through the private network. The database does not require a public IP address.

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

### 2. Build Process
```bash
# Clean and build project
mvn clean package -DskipTests

# Run tests
mvn test

# Deploy to JFrog
mvn deploy
```

## Application Deployment

### 1. Tomcat Configuration
```bash
# Create tomcat.service
sudo tee /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

### 2. Nginx Configuration
```nginx
# /etc/nginx/conf.d/app.conf
upstream backend {
    server internal-nlb-xxx.elb.amazonaws.com:8080;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static/ {
        proxy_pass https://your-cloudfront-distribution.cloudfront.net;
    }
}
```

## Load Balancing and Auto Scaling

### 1. Launch Template Configuration
```bash
aws ec2 create-launch-template \
    --launch-template-name WebServerTemplate \
    --version-description WebServerVersion1 \
    --launch-template-data '{
        "ImageId": "ami-xxx",
        "InstanceType": "t3.micro",
        "SecurityGroupIds": ["sg-xxx"],
        "UserData": "IyEvYmluL2Jhc2gKCiMgSW5zdGFsbCBOZ2lueApzdWRvIHl1bSBpbnN0YWxsIG5naW54IC15Cg=="
    }'
```

### 2. Auto Scaling Group
```bash
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name WebServerASG \
    --launch-template LaunchTemplateName=WebServerTemplate,Version='$Latest' \
    --min-size 2 \
    --max-size 6 \
    --desired-capacity 2 \
    --vpc-zone-identifier "subnet-xxx,subnet-yyy" \
    --target-group-arns "arn:aws:elasticloadbalancing:region:account-id:targetgroup/your-target-group/xxx" \
    --health-check-type ELB \
    --health-check-grace-period 300
```

# Monitoring and Maintenance

## CloudWatch Setup

### 1. Metrics Configuration
```bash
# Create custom metric for memory usage
cat << EOF > /opt/aws/scripts/memory-metrics.sh
#!/bin/bash
MEMORY_USAGE=\$(free | grep Mem | awk '{print \$3/\$2 * 100.0}')
aws cloudwatch put-metric-data \
    --metric-name MemoryUsage \
    --namespace CustomMetrics \
    --value \$MEMORY_USAGE \
    --dimensions InstanceId=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
EOF

# Add to crontab
echo "* * * * * /opt/aws/scripts/memory-metrics.sh" | crontab -
```

### 2. Log Management
```bash
# Configure CloudWatch agent
cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/tomcat/logs/catalina.out",
                        "log_group_name": "/aws/tomcat/application",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ]
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ]
            }
        }
    }
}
EOF
```

# Security Best Practices

## 1. Network Security
- Implement network ACLs
- Use security groups effectively
- Enable VPC Flow Logs
- Configure AWS WAF

## 2. Application Security
- Regular security patches
- Implement AWS Shield
- Use AWS Secrets Manager
- Enable AWS GuardDuty

## 3. Data Security
- Enable encryption at rest
- Use SSL/TLS for data in transit
- Regular security audits
- Implement backup strategies

# Troubleshooting Guide

## Common Issues and Solutions

### 1. Connection Issues
```bash
# Check connectivity
telnet database-endpoint 3306

# Verify security group rules
aws ec2 describe-security-groups --group-ids sg-xxx

# Test load balancer health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/your-target-group/xxx
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

# Install dependencies
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
- **Blog**: [ProDevOpsGuy](https://blog.prodevopsguytech.com)
- **Telegram Community**: [Join Here](https://t.me/prodevopsguy)
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