# Deploy Java Application on AWS 3-Tier Architecture	


## Table of Content 
    
1. Project Overview
2. Architecture Overview
3. Pre-Requisites
4. Infrastructure Setup
    - VPC and Networking
    - Security Configuration
    - Database Layer
5. Application Setup
    - Build Environment
    - Application Deployment
    - Load Balancing and Auto Scaling
6. Monitoring and Maintenance
7. Security Best Practices
8. Troubleshooting Guide
9. Contributing



## Project Overview 
### Introduction 
This project demonstrates the deployment of a production-grade Java web application using AWS's robust 3-tier architecture. The implementation follows cloud-native best practices, ensuring high availability, scalability, and security across all application tiers.

### Key Features
    - High Availability: Multi-AZ deployment with automated failover
    - Auto Scaling: Dynamic resource allocation based on demand
    - Security: Defense-in-depth approach with multiple security layers
    - Monitoring: Comprehensive logging and monitoring setup
    - Cost Optimization: Efficient resource utilization and management

## Architecture Overview
### Infrastructure Components

#### 1. Presentation Tier (Frontend)

    - Nginx web servers in Auto Scaling Group
    - Public-facing Network Load Balancer
    - CloudFront Distribution for static content

#### 2. Application Tier (Backend)

    - Apache Tomcat servers in Auto Scaling Group
    - Internal Network Load Balancer
    - Session management with Amazon ElastiCache

#### 3. Data Tier

    - Amazon RDS MySQL in Multi-AZ configuration
    - Automated backups and point-in-time recovery
    - Read replicas for read-heavy workloads

### Network Architecture
    - VPC Design
        + Two separate VPCs (192.168.0.0/16 and 172.32.0.0/16)
        + Public and private subnets across multiple AZs
        + Transit Gateway for inter-VPC communication

## Pre-Requisites 
### Required Accounts and Tools
#### 1. AWS Account Setup
        - Create an AWS Free Tier Account
        - Create an AWS Free Tier Account 
    ```sh
        # For Linux
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install

        # For macOS
        brew install awscli

        # Configure AWS CLI
        aws configure
    ```
#### 2. Deployment Tools 
    - Git: Version control system 

    