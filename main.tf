provider "aws" {
  region = "ap-south-1"  # Mumbai Region
}

# Fetch Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch a Single Default Subnet in Mumbai Region
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  id = tolist(data.aws_subnets.default_subnets.ids)[0]  # Pick the first subnet
}

# Security Group for Kubernetes and Ansible
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH from Jenkins Machine (Ansible Master)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to Jenkins IP if possible
  }

  # Allow Kubernetes API Server (6443) and NodePort range
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Kubernetes Worker + Ansible Node
resource "aws_instance" "worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [aws_security_group.k8s_sg.name]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  # Install Kubernetes, Docker, and Ansible
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io kubeadm kubelet kubectl ansible
    sudo systemctl enable docker
    sudo systemctl start docker
  EOF
}

# Output Instance IP
output "worker_ansible_ip" {
  value = aws_instance.worker_ansible.public_ip
}
