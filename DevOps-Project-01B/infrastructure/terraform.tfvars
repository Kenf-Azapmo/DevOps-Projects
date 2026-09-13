aws_region         = "us-east-1"
environment        = "dev"
vpc_cidr           = "192.168.0.0/16"
public_subnets     = ["192.168.1.0/24", "192.168.2.0/24"]
app_subnets        = ["192.168.3.0/24", "192.168.4.0/24"]
db_subnets         = ["192.168.5.0/24", "192.168.6.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

app_port             = 8080
instance_type        = "t3.micro"
asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4

db_name                    = "appdb"
db_username                = "admin"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_max_allocated_storage   = 50
db_backup_retention_period = 1
db_backup_window           = "03:00-04:00"
db_maintenance_window      = "Sun:04:00-Sun:05:00"

app_health_check_path = "/actuator/health"

db_engine_version      = "8.4"
db_deletion_protection = false
db_skip_final_snapshot = true

domain_name = "azapmo.com"

alert_email = "azapmokenfack@gmail.com"
