# SECURITY

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for App Load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic from the internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


# EC2 Instances Security Group (for the App EC2 instances)
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Security group for EC2 App instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application traffic from the ALB"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

}

# Database Security Group (for the RDS instances)
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id = aws_security_group.db.id
  description       = "Allow database traffic from the App EC2 instances"
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"

  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound traffic from RDS"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

}
