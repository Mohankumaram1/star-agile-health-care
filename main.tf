# Provider Configuration (Mumbai Region)
provider "aws" {
  region     = "ap-south-1"
}

# Get the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Manually specify a subnet ID (replace this with your actual subnet ID)
data "aws_subnet" "selected" {
  id = "subnet-04441ad5ed7050ca2"  # Replace with your working subnet ID
}

# Security Group for Kubernetes and SSH
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH from Jenkins Machine (Ansible Master)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change this to Jenkins machine IP
  }

  # Allow Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort range
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

# Jenkins (Ansible Master) is already running, so we create only worker nodes

# Kubernetes Worker + Ansible Node
resource "aws_instance" "worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name        = "mohanm"
  associate_public_ip_address = true  # Enable public IP

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  # Install Kubernetes and Ansible Worker
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl ansible

    # Disable swap (required for Kubernetes)
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab

    # Enable Kubernetes service
    sudo systemctl enable kubelet
  EOF
}

# Output Worker Node IP
output "worker_ansible_ip" {
  value = aws_instance.worker_ansible.public_ip
}
