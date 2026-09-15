resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/${var.environment}/system"
  retention_in_days = 14

  tags = {
    Name        = "${var.environment}-system-logs"
    Environment = var.environment
  }
}


resource "aws_cloudwatch_log_group" "docker" {
  name              = "/aws/${var.environment}/docker"
  retention_in_days = 14

  tags = {
    Name        = "${var.environment}-docker-logs"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name = "/${var.environment}/cloudwatch-agent-config"

  type = "String"

  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }

    metrics = {
      namespace = "${var.environment}/EC2"

      append_dimensions = {
        AutoScalingGroupName = "$${aws:AutoScalingGroupName}"
        InstanceId           = "$${aws:InstanceId}"
        InstanceType         = "$${aws:InstanceType}"
      }

      metrics_collected = {
        cpu = {
          measurement = [
            "cpu_usage_idle",
            "cpu_usage_user",
            "cpu_usage_system"
          ]

          metrics_collection_interval = 60

          totalcpu = true
        }

        mem = {
          measurement = [
            "mem_used_percent"
          ]

          metrics_collection_interval = 60
        }

        disk = {
          measurement = [
            "used_percent"
          ]

          resources = [
            "/"
          ]

          metrics_collection_interval = 60
        }

        diskio = {
          measurement = [
            "diskio_read_bytes",
            "diskio_write_bytes"
          ]

          metrics_collection_interval = 60
        }

        netstat = {
          measurement = [
            "tcp_established",
            "tcp_time_wait"
          ]

          metrics_collection_interval = 60
        }
      }
    }

    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/messages"
              log_group_name  = aws_cloudwatch_log_group.system.name
              log_stream_name = "{instance_id}/messages"
              # retention_in_days = 14
            },
            {
              file_path       = "/var/log/cloud-init-output.log"
              log_group_name  = aws_cloudwatch_log_group.system.name
              log_stream_name = "{instance_id}/cloud-init-output"
              # retention_in_days = 14
            },
            {
              file_path       = "/var/lib/docker/containers/*/*.log"
              log_group_name  = aws_cloudwatch_log_group.docker.name
              log_stream_name = "{instance_id}/docker"
              # retention_in_days = 14
            }
          ]
        }
      }
    }
  })

  tags = {
    Name        = "${var.environment}-cloudwatch-agent-config"
    Environment = var.environment
  }
}