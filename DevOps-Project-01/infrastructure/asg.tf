# ASG Module 

resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.name.id]

  user_data = base64encode(<<EOF
#!/bin/bash

yum update -y

amazon-linux-extras install java-openjdk11 -y

yum install -y wget

cd /opt

wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.107/bin/apache-tomcat-9.0.107.tar.gz

tar -xzf apache-tomcat-9.0.107.tar.gz

mv apache-tomcat-9.0.107 tomcat

/opt/tomcat/bin/startup.sh

EOF
)



  /*
  user_data = base64encode(<<-EOF
              #!/bin/bash
                yum update -y
                yum install -y java-11-amazon-corretto
                yum install -y tomcat
                systemctl enable tomcat
                systemctl start tomcat
              EOF
  ) 
  */

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                      = "${var.environment}-asg"
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.main.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  max_size         = var.asg_max_size
  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}