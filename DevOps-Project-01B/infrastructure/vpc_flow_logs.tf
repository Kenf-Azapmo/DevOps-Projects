resource "aws_flow_log" "vpc" {
  vpc_id = aws_vpc.main.id

  traffic_type = "ALL"

  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  log_destination_type = "cloud-watch-logs"

  tags = {
    Name        = "${var.environment}-vpc-flow-log"
    Environment = var.environment
  }
}   