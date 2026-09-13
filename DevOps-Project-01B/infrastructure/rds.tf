# RDS 
resource "aws_db_subnet_group" "mysql" {
  name       = "${var.environment}-mysql-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name        = "${var.environment}-mysql-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "mysql" {
  identifier            = "${var.environment}-mysql"
  engine                = "mysql"
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  multi_az = true

  db_subnet_group_name = aws_db_subnet_group.mysql.name

  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false

  storage_encrypted = true

  backup_retention_period = var.db_backup_retention_period

  backup_window = var.db_backup_window

  maintenance_window = var.db_maintenance_window

  deletion_protection = var.db_deletion_protection

  skip_final_snapshot = var.db_skip_final_snapshot

  copy_tags_to_snapshot = true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = "${var.environment}-mysql"
    Environment = var.environment
  }
}