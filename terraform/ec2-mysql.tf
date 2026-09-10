data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "mysql" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.private_data[0].id
  vpc_security_group_ids      = [aws_security_group.data.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_instance_profile.name
  key_name                    = "vockey"
  associate_public_ip_address = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/scripts/mysql-user-data.sh", {
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
  }))

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
