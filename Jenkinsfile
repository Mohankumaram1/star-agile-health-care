pipeline {
    agent any
    stages {
        stage('Provision Infrastructure') {
            steps {
                sh "terraform init"
                sh "terraform apply -auto-approve"
            }
        }
        stage('Configure Kubernetes') {
            steps {
                sh "ansible-playbook -i inventory install-k8s.yml"
                sh "ansible-playbook -i inventory setup-master.yml"
                sh "ansible-playbook -i inventory setup-workers.yml"
            }
        }
        stage('Deploy Banking App') {
            steps {
                sh "ansible-playbook -i inventory deploy-app.yml"
            }
        }
    }
}
