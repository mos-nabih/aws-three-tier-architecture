data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  count = var.app_instance_count

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.app_instance_type
  subnet_id                   = aws_subnet.app_private[count.index % length(aws_subnet.app_private)].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/scripts/app-user-data.sh", {
    database_host = aws_instance.database.private_ip
    database_port = var.database_port
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "app-instance-${count.index + 1}"
    Tier = "application"
  }
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.app_instance_type
  subnet_id                   = aws_subnet.data_private[0].id
  vpc_security_group_ids      = [aws_security_group.data.id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/scripts/database-user-data.sh", {
    database_port = var.database_port
  })

  metadata_options {
    # Enforce IMDSv2 for enhanced security by requiring session tokens and disabling the endpoint for older versions of IMDS.
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "database-placeholder"
    Tier = "data"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count = length(aws_instance.app)

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}
