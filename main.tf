##################################
provider "aws" {
  region = var.region

}


data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.name]
  user_data              = file("cloud-init-master.sh")
  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s-worker" {
  count                  = 2
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.name]
  user_data              = file("cloud-init-worker.sh")
  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

resource "aws_eip" "k8s_master_eip" {
  instance = aws_instance.k8s-master.id

}

resource "aws_eip" "k8s_worker_eip" {
  count    = 2
  instance = aws_instance.k8s-worker[count.index].id

}