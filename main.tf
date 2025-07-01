##################################
provider "aws" {
  region = var.region

}


data "aws_ami" "latest_amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.7.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "k8s_sg" {
  name = "k8s-cluster-sg"
  #vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s-master" {
  ami                    = data.aws_ami.latest_amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.name]
  user_data              = file("scripts/cloud-init-master.sh")

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s-worker" {
  count                  = 2
  ami                    = data.aws_ami.latest_amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.name]
  user_data              = file("scripts/cloud-init-worker.sh")
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
  tags = {
    Name = "worker-${count.index + 1}"
  }
}

resource "aws_eip" "k8s_master_eip" {
  instance = aws_instance.k8s-master.id

}

resource "aws_eip" "k8s_worker_eip" {
  count    = 2
  instance = aws_instance.k8s-worker[count.index].id

}