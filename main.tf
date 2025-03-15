# -----------------------------
# 1️⃣ Provider Configuration
# -----------------------------
provider "aws" {
  region     = "ap-south-1" # Mumbai
}

# -----------------------------
# 2️⃣ Get Default VPC & Specific Subnet
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "availability-zone"
    values = ["ap-south-1a"]  # Ensure only 1 subnet is selected
  }
}

# -----------------------------
# 3️⃣ Security Group for K8s, Ansible, SSH
# -----------------------------
resource "aws_security_group" "k8s_sg" {
  vpc_id = data.aws_vpc.default.id

  # Allow SSH (22) from Jenkins (Ansible Master)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with Jenkins IP if possible
  }

  # Allow Kubernetes API Server (6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort Services (30000-32767)
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

# -----------------------------
# 4️⃣ Create Kubernetes Worker + Ansible Node
# -----------------------------
resource "aws_instance" "worker_ansible" {
  ami             = "ami-00bb6a80f01f03502"  # Ubuntu 22.04 LTS (Mumbai)
  instance_type   = "t2.medium"
  subnet_id       = data.aws_subnet.selected.id  # Use the selected subnet
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name        = "mohanm"

  tags = {
    Name = "K8s-Worker-Ansible"
  }

  # Install Kubernetes and Ansible Worker
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io kubeadm kubelet kubectl ansible -y
    sudo systemctl enable docker && sudo systemctl start docker
    sudo systemctl enable kubelet && sudo systemctl start kubelet

    # Get the Kubeadm Join command from Jenkins Master
    KUBE_JOIN_CMD=$(curl -s http://JENKINS_MASTER_IP:5000/join)
    if [ -n "$KUBE_JOIN_CMD" ]; then
      sudo $KUBE_JOIN_CMD
    fi
  EOF
}

# -----------------------------
# 5️⃣ Output Worker IP
# -----------------------------
output "worker_ansible_ip" {
  value = aws_instance.worker_ansible.public_ip
}
