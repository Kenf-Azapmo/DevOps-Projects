# Monitoring Module 

#Cloudwatch Log Group for application logs  

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.environment}-application"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Application = "${var.environment}-application"
  }
}

# RDS Cloudwatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 CPU utilization ie alarm when RDS CPU utilisation exeeds a certain persentage."
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.environment}-rds-high-cpu"
    Environment = var.environment
  }
}
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "268435456" # 256MB in bytes
  alarm_description   = "This metric monitors RDS free storage space."
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.environment}-rds-memory-alarm"
    Environment = var.environment
  }
}

# Auto Scaling group Cloudwatch Alarm 
resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = "${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors EC2 CPU utilization for Auto Scaling Group."
  alarm_actions       = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name        = "${var.environment}-asg-cpu-alarm"
    Environment = var.environment
  }
}