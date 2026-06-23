aws_region         = "us-east-1"
environment        = "dev"
vpc_cidr           = "192.168.0.0/16"
public_subnets     = ["192.168.1.0/24", "192.168.2.0/24"]
private_subnets    = ["192.168.3.0/24", "192.168.4.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]
instance_type      = "t3.micro"
ami_id             = "ami-0c02fb55956c7d316" # Amazon Linux 2
#image_id "ami-0c02fb55956c7d316" # Amazon Linux 2
db_username = "admin"
db_password = "kenfackazapmo"
key_name    = "azapmo"