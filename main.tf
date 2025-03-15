# PROVIDER CONFIGURATION
provider "aws" {
  region     = "ap-south-1"  # Mumbai region
}

# DEFAULT VPC
data "aws_vpc" "default" {
  default = true
}

# SELECT A SINGLE PUBLIC SUBNET
data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# SECURITY GROUP FOR SSH, KUBERNETES, ANSIBLE
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

# CREATE KUBERNETES MASTER NODE
resource "aws_instance" "k8s_master" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Master"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tee /home/ubuntu/kubeadm_init.log
    mkdir -p /home/ubuntu/.kube
    cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config
  EOF
}

# CREATE WORKER + ANSIBLE NODE
resource "aws_instance" "worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl docker.io ansible
    sudo systemctl enable docker
    sudo systemctl start docker
  EOF
}

# OUTPUTS
output "k8s_master_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_ansible_ip" {
  value = aws_instance.worker_ansible.public_ip
}
