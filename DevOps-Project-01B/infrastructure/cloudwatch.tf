resource "aws_cloudwatch_log_group" "application" {
  # name              = "/aws/vpc/${var.environment}/application"
  name              = "/aws/${var.environment}/application"
  retention_in_days = 14

  tags = {
    Name        = "${var.environment}-application-logs"
    Environment = var.environment
  }
}


# ALB monitoring
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name = "${var.environment}-alb-unhealthy-hosts"

  alarm_description = "Alarm when the ALB has unhealthy targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnhealthyHostCount"

  statistic = "Maximum"
  period    = 60

  evaluation_periods = 2
  threshold          = 1

  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = aws_alb.main.arn_suffix
    TargetGroup  = aws_alb_target_group.app.arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  #aws_sns_topic.alerts.arn

}

# ALB HTTP 5xx alarm
resource "aws_cloudwatch_metric_alarm" "alb_http_5xx" {
  alarm_name = "${var.environment} -alb_http_5xx"

  alarm_description = "Alarm when the ALB returns 5xx response / errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  statistic = "Sum"
  period    = 300

  evaluation_periods = 2
  threshold          = 1

  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = aws_alb.main.arn_suffix
    TargetGroup  = aws_alb_target_group.app.arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]

}


# RDS monitoring
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name = "${var.environment}-rds-cpu"

  alarm_description = "Alarm when RDS CPU utilization exceeds 80%"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  statistic = "Average"
  period    = 300

  evaluation_periods = 2
  threshold          = 80

  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# RDS storage alarm
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name = "${var.environment}-rds_low-storage"

  alarm_description = "Alarm when RDS free storage falls below 2 GiB"

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  statistic = "Average"
  period    = 300

  evaluation_periods = 2

  threshold = 2147483648

  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}


# EC2 CPU alarm
resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name = "${var.environment}-asg-high-cpu"

  alarm_description = "Alarm when the application Auto Scaling Group has high CPU utilization"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic = "Average"
  period    = 300

  evaluation_periods = 2
  threshold          = 80

  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}


resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "vpc/${var.environment}/flow-logs"
  retention_in_days = 14

  tags = {
    Name        = "${var.environment}-vpc-flow-logs"
    Environment = var.environment
  }

}


# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-vpc-flow-logs-role"
    Environment = var.environment
  }
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_policy" "vpc_flow_logs" {
  name        = "${var.environment}-vpc-flow-logs-policy"
  description = "Policy for VPC Flow Logs to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}