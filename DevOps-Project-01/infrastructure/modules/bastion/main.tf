# Bastion Module 

resource "aws_instance" "bastion" { 
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [var.bastion_sg_id]

  key_name = var.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.environment}-bastion"
    Environment =var.environment
  }
}   