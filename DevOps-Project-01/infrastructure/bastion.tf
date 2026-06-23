# Bastion Module 

resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id

  vpc_security_group_ids = [aws_security_group.bastion.id]

  key_name = var.key_name

  associate_public_ip_address = true

  tags = {
    Name        = "${var.environment}-bastion"
    Environment = var.environment
  }
}    