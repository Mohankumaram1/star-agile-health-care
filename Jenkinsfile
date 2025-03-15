pipeline {
    agent any
    stages {
        stage('Terraform Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }
        stage('Set Permissions for SSH Key') {
            steps {
                sh 'chmod 400 mohanm.pem'  // Ensure correct SSH key permissions
            }
        }
        stage('Ansible Configure Worker') {
            steps {
                sh 'su - devops'
                sh 'ansible-playbook -i inventory add_devops.yml'
                sh 'ansible-playbook -i inventory ansible_login.yml'
                sh 'ansible-playbook -i inventory add_ssh_key.yml'
            }
        }
        stage('Join Worker to Kubernetes') {
            steps {
                sh 'ansible-playbook -i inventory kube_join.yml'
            }
        }
        stage('Deploy Kubernetes Application') {
            steps {
                sh 'ansible-playbook -i inventory deploy_app.yml'
            }
        }
    }
}
