pipeline {
    agent any
    stages {
        stage('Terraform Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }
        stage('Ansible Configure Worker') {
            steps {
                sh 'ansible-playbook -i inventory ansible_login.yml'
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
