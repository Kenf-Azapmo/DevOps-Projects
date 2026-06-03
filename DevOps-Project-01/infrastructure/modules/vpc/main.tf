#VPC Module 

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

#INternet Getway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.name.id

  tags = {
    Name = "${var.environment}-igw"
    Environment = var.environment
  }
}

#public Subnet
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)    
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.environment}-public-subnet ${count.index + 1}"
    Environment = var.environment
  }
}

#Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)    
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.environment}-private-subnet ${count.index + 1}"
    Environment = var.environment
  }
}

#Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.public_subnets) # Create one EIP for each public subnet
  #vpc = true

  tags = {
    Name = "${var.environment}-nat-eip ${count.index + 1}"
    Environment = var.environment
  }
}

#NAT Gateway
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnets) # Create one NAT Gateway for each public subnet
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.environment}-nat-gateway ${count.index + 1}"
    Environment = var.environment
  }
}

#Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

#Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  count = length(var.private_subnets) # Create one route table for each private subnet

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

#Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

#VPC Flow Logs
resource "aws_flow_log" "main" {
  vpc_id = aws_vpc.main.id
  traffic_type = "ALL"
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn = aws_iam_role.flow_logs.arn
}

#CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name = "/aws/vpc/${var.environment}/flow-logs"
  retention_in_days = 30

    tags = {
        Environment = var.environment
    }
}   


#IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#IAM Policy for VPC Flow Logs
resource "aws_iam_policy" "flow_logs" {
  name = "${var.environment}-vpc-flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

