data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]

    # values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  /* 
  network_interfaces {
    associate_public_ip_address = false

    security_groups = [aws_security_group.app.id]
  }   */

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
#!/bin/bash

set -e

dnf update -y

dnf install -y docker amazon-cloudwatch-agent

systemctl enable docker
systemctl start docker

docker run -d \
  --name web-app \
  --restart always \
  -p ${var.app_port}:80 \
  nginx:latest

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c ssm:${aws_ssm_parameter.cloudwatch_agent_config.name}
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-app-instance"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-app-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = aws_subnet.app[*].id

  target_group_arns = [aws_alb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

# This is to make the the ASG automatically replace instances when the luch template changes
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  depends_on = [aws_iam_role_policy_attachment.ec2_cloudwatch_agent,
    aws_iam_role_policy.cloudwatch_agent
  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-instance"
    propagate_at_launch = true
  }


  /*

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }   */

}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.environment}-cpu-target-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

