# ALB
resource "aws_alb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "app" {
  name     = "${var.environment}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance" 

  health_check {
    enabled             = true
    path                = var.app_health_check_path
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Name        = "${var.environment}-app-tg"
    Environment = var.environment
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.main.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate.app.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }

  depends_on = [
    aws_acm_certificate_validation.app
  ]  

}


