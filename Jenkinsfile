pipeline {
    agent any
 
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE           = "milanviradiya97/my-angular-app"
        ANSIBLE_SERVER_IP      = "<ansible-controller-private-ip>"
        ANSIBLE_USER           = "ec2-user"
        BUILD_TAG              = "${BUILD_NUMBER}"
    }
 
    stages {
 
        stage('1 - Git Checkout') {
            steps {
                echo '====== Pulling Angular code from GitHub ======'
                git branch: 'main',
                    url: 'https://github.com/milanviradiya1997/my-angular-app.git'
                echo 'Code pulled!'
            }
        }
 
        stage('2 - npm Install') {
            steps {
                echo '====== Installing npm packages ======'
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm use 18
                    node --version
                    npm --version
                    npm install
                '''
                echo 'npm install complete!'
            }
        }
 
        stage('3 - Angular Production Build') {
            steps {
                echo '====== Building Angular for Production ======'
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm use 18
                    npm run build -- --configuration production
                '''
                echo 'Angular build done! dist/ folder created.'
            }
        }
 
        stage('4 - Docker Build') {
            steps {
                echo '====== Building Docker Image ======'
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${BUILD_TAG} ${DOCKER_IMAGE}:latest"
                sh "docker images | grep my-angular-app"
                echo 'Docker image built!'
            }
        }
 
        stage('5 - Docker Push to Hub') {
            steps {
                echo '====== Pushing to Docker Hub ======'
                sh """
                    echo ${DOCKER_HUB_CREDENTIALS_PSW} | \
                    docker login -u ${DOCKER_HUB_CREDENTIALS_USR} \
                    --password-stdin
                """
                sh "docker push ${DOCKER_IMAGE}:${BUILD_TAG}"
                sh "docker push ${DOCKER_IMAGE}:latest"
                echo 'Image pushed to Docker Hub!'
            }
        }
 
        stage('6 - Copy Files to Ansible Controller') {
            steps {
                echo '====== Copying Helm chart + Ansible to ansible-controller ======'
                sshagent(['ansible-server-key']) {
                    sh """
                        scp -o StrictHostKeyChecking=no -r \
                          ansible/ ${ANSIBLE_USER}@${ANSIBLE_SERVER_IP}:/home/ec2-user/
                        scp -o StrictHostKeyChecking=no -r \
                          angular-chart/ ${ANSIBLE_USER}@${ANSIBLE_SERVER_IP}:/home/ec2-user/
                    """
                }
                echo 'Files copied!'
            }
        }
 
        stage('7 - Ansible: Helm Deploy + Prometheus') {
            steps {
                echo '====== Running Ansible Playbook ======'
                sshagent(['ansible-server-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                          ${ANSIBLE_USER}@${ANSIBLE_SERVER_IP} \
                          "ansible-playbook \
                            /home/ec2-user/ansible/playbook.yml \
                            -i /home/ec2-user/ansible/inventory.ini \
                            --extra-vars 'build_number=${BUILD_TAG}'"
                    """
                }
                echo 'Angular app deployed to EKS via Helm!'
            }
        }
    }
 
    post {
        success {
            echo 'SUCCESS! Angular deployed + Prometheus monitoring active!'
        }
        failure {
            echo 'PIPELINE FAILED — check stage logs above!'
        }
        always {
            sh "docker rmi ${DOCKER_IMAGE}:${BUILD_TAG} || true"
            sh 'docker logout || true'
            sh 'rm -rf dist/ node_modules/ || true'
            echo 'Cleanup complete.'
        }
    }
}
