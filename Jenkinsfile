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
                sh 'chmod 400 mohanm.pem' // Ensure correct SSH key permissions
                sh 'chmod 777 mohankey.pem'
            }
        }
        stage('Ansible Configure Worker') {
            steps {
                sh 'su - devops'
                sh 'sudo -u devops ansible-playbook -i inventory add_devops.yml'
                sh 'sudo -u devops ansible-playbook -i inventory ansible_login.yml'
                sh 'sudo -u devops ansible-playbook -i inventory add_ssh_key.yml'
            }
        }
        stage('Join Worker to Kubernetes') {
            steps {
                sh 'sudo -u devops ansible-playbook -i inventory kube_join.yml'
            }
        }
        stage('Deploy Kubernetes Application') {
            steps {
                sh 'sudo -u devops ansible-playbook -i inventory deploy_app.yml'
            }
        }
    }
}
