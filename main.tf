provider "aws" {
  region = "ap-south-1"
}

# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get Default Subnet (Pick one from default VPC)
data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Security Group for Kubernetes
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Master Node
resource "aws_instance" "master" {
  ami             = "ami-00bb6a80f01f03502"  # Replace with latest Ubuntu AMI
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.default.id
  security_groups = [aws_security_group.k8s_sg.name]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Master"
  }
}

# Worker Nodes
resource "aws_instance" "worker" {
  count          = 2
  ami           = "ami-00bb6a80f01f03502"
  instance_type = "t2.medium"
  subnet_id     = data.aws_subnet.default.id
  security_groups = [aws_security_group.k8s_sg.name]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-${count.index}"
  }
}

# Output Public IPs
output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = aws_instance.worker[*].public_ip
}
