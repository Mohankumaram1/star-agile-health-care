provider "aws" {
  region = "ap-south-1"
}

# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get a specific Public Subnet in the default VPC
data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }

  filter {
    name   = "availability-zone"
    values = ["ap-south-1b"]  # Change if needed
  }
}

# Security Group for Kubernetes and Ansible
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to restrict access
  }

  # Allow Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort Range
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

# Kubernetes Master Node
resource "aws_instance" "k8s_master" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [aws_security_group.k8s_sg.name]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Master"
  }

  # Bootstrap Kubernetes Master
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl
    kubeadm init --apiserver-advertise-address=$(curl -s ifconfig.me) --pod-network-cidr=192.168.0.0/16
  EOF
}

# Kubernetes Worker + Ansible Node
resource "aws_instance" "k8s_worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [aws_security_group.k8s_sg.name]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  # Install Kubernetes Worker & Ansible
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl ansible
  EOF
}

# Output Instance IPs
output "k8s_master_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "k8s_worker_ansible_ip" {
  value = aws_instance.k8s_worker_ansible.public_ip
}
