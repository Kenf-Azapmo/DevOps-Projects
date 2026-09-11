resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Private Subnets For the App EC2 instances (ASG)
resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-app-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# DB Subnets (for RDS instances)
resource "aws_subnet" "db" {
  count             = length(var.db_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-db-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.public_subnets) # Create one EIP for each public subnet
  domain = "vpc"                      # This is optional, as the default is "vpc" for VPCs

  tags = {
    Name        = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets) # Creates a NAT Gateway in each public subnet
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main] # Ensure NAT Gateway is created after the Internet Gateway

  tags = {
    Name        = "${var.environment}-nat-gateway-${count.index + 1}"
    Environment = var.environment
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # destination_cidr_block
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Private Route Table for App EC2 instances (One per private app subnet)
resource "aws_route_table" "app" {
  count  = length(var.app_subnets) # Creates a route table for each private app subnet
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id

    # nat_gateway_id = aws_nat_gateway.main[count.index % length(var.public_subnets)].id
  }

  tags = {
    Name        = "${var.environment}-app-rt-${count.index + 1}"
    Environment = var.environment
  }
}


# DB Private Route Table (One per private db subnet) The database subnets should not have internet access
resource "aws_route_table" "db" {
  count  = length(var.db_subnets) # Creates a route table for each private db subnet
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-db-rt-${count.index + 1}"
    Environment = var.environment
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations for Private App Subnets
resource "aws_route_table_association" "app" {
  count          = length(var.app_subnets)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# Route Table Associations for Private DB Subnets
resource "aws_route_table_association" "db" {
  count          = length(var.db_subnets)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}
