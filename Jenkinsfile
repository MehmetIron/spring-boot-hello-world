pipeline {
    agent {
        label 'master'
    }
    environment{
        PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        APP_NAME = "desowa"
        AWS_REGION = "us-east-1"
        CFN_KEYPAIR="mehmet-${APP_NAME}-${BUILD_NUMBER}.key"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_REPO_NAME = "${APP_NAME}/spring-hello"
    }

    stages {
        stage('creating ECR Repository') {
            steps {
                echo 'creating ECR Repository'
                sh """
                aws ecr create-repository \
                  --repository-name ${APP_REPO_NAME}-b${BUILD_NUMBER} \
                  --image-scanning-configuration scanOnPush=false \
                  --image-tag-mutability MUTABLE \
                  --region ${AWS_REGION}
                """
            }
        }

        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh "docker run --rm -v $HOME/.m2:/root/.m2 -v $WORKSPACE:/app -w /app maven:3.6-openjdk-11 mvn clean package"
            }
        }

        stage('building Docker Image') {
            steps {
                echo 'building Docker Image'
                sh 'docker build --force-rm -t "$ECR_REGISTRY/$APP_REPO_NAME-b${BUILD_NUMBER}:latest" .'
                sh 'docker image ls'
            }
        }
        stage('pushing Docker image to ECR Repository'){
            steps {
                echo 'pushing Docker image to ECR Repository'
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin "$ECR_REGISTRY"'
                sh 'docker push "$ECR_REGISTRY/$APP_REPO_NAME-b${BUILD_NUMBER}:latest"'
            }
        }

        stage('Create Key Pair') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                sh "aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${CFN_KEYPAIR} --query KeyMaterial --output text > ${CFN_KEYPAIR}"
                sh "chmod 400 ${CFN_KEYPAIR}"
                sh "mkdir -p ${JENKINS_HOME}/.ssh"
                sh "mv ${CFN_KEYPAIR} ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}"
            }
        }

        // stage('create-cluster'){
        //     agent any
        //     steps{
        //         sh """"
        //         eksctl create cluster \
        //             --name desowa-spring \
        //             --version 1.18 \
        //             --region us-east-1 \
        //             --nodegroup-name my-nodes \
        //             --node-type t2.small \
        //             --nodes 1 \
        //             --nodes-min 1 \
        //             --nodes-max 2 \
        //             --ssh-access \
        //             --ssh-public-key ${CFN_KEYPAIR} \
        //             --managed
        //         """
        //     }
        // }

        stage('apply-k8s'){
            agent any
            steps {
                sh "kubectl apply -f k8s/."
            }
        }
    }

    // post {
    //     always {
    //         echo 'Deleting all local images'
    //         sh 'docker image prune -af'
    //         echo 'Delete the Image Repository on ECR'
    //         sh """
    //             aws ecr delete-repository \
    //               --repository-name ${APP_REPO_NAME}-b${BUILD_NUMBER} \
    //               --region ${AWS_REGION}\
    //               --force
    //             """
    //         echo "Delete existing key pair using AWS CLI"
    //         sh "aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${CFN_KEYPAIR}"
    //         sh "rm -rf ${CFN_KEYPAIR}"
    //     }
    // }
}