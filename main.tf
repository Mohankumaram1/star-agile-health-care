provider "aws" {
  region = "ap-south-1"  # Mumbai Region
}

# Use Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get Default Subnet
data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Security Group for SSH, Kubernetes, and Ansible
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH from Jenkins Machine (Ansible Master)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to Jenkins Machine IP for security
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

# Create Kubernetes Worker + Ansible Worker Node
resource "aws_instance" "worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]  # Fixed Issue
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  # Install Kubernetes, Ansible & Setup Auto Join
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y kubeadm kubelet kubectl ansible

    # Fetch Kubernetes Join Command from Jenkins Master
    echo "[TASK] Fetching kubeadm join command"
    JOIN_CMD=$(ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/mohanm.pem ubuntu@<JENKINS_MASTER_IP> "kubeadm token create --print-join-command")

    # Execute Join Command
    echo "[TASK] Joining Kubernetes Cluster"
    sudo $JOIN_CMD
  EOF
}

# Generate Dynamic Ansible Inventory
resource "local_file" "ansible_inventory" {
  content  = <<EOF
[worker]
${aws_instance.worker_ansible.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/mohanm.pem
EOF
  filename = "inventory.ini"
}

# Output Worker Node IP
output "worker_ansible_ip" {
  value = aws_instance.worker_ansible.public_ip
}
