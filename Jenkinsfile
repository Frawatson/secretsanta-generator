pipeline {
    agent any
    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        DOCKERHUB_CREDENTIALS=credentials('docker-cred')
        KUBERNETES_CREDENTIALS=credentials('kubeconfig')
        SCANNER_HOME=tool 'sonar-scanner'
    }

    stages {
        stage ('Maven Compile') {
            steps{
                sh "mvn clean compile"
            }
        }
        stage ('Unit Test') {
            steps{
                sh "mvn test"
            }
        }
        stage ('Owasp Check') {
                    steps{
                        dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'DC'
                        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                    }
        }

        stage ('Sonar Analysis') {
            steps{
                sh ''' mvn sonar:sonar -Dsonar.url=http://192.168.56.110:9000/ -Dsonar.login=sqp_405471ff19899dffe397813a0fcf517747dab889 -Dsonar.projectKey=secret-santa \
                   -Dsonar.projectName=secret-santa -Dsonar.java.binaries=. '''

            }
        }
        stage ('Maven Build') {
            steps{
                sh "mvn clean package"
            }
        }


        stage ('Docker Build') {
            steps{
                script {
                    // This step should not normally be used in your script. Consult the inline help for details.
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker build -t santagenerator ."
                    }
                }
            }
        }

        stage ('Docker Push') {
            steps{
                script {
                    // This step should not normally be used in your script. Consult the inline help for details.
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker tag santagenerator frawatson/santagenerator:latest"
                        sh "docker push frawatson/santagenerator:latest"
                    }
                }
            }
        }
        stage ('Trivy Scan') {
                    steps{
                        script {
                            withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                                sh "trivy image santagenerator > trivy-report.txt --reset"
                            }
                        }
                    }
        }
        stage ('Kubernetes Deploy') {
            steps{
                script {
                    withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kubeconfig', namespace: 'dev', restrictKubeConfigAccess: false, serverUrl: 'https://192.168.56.106:6443') {
                        sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                        sh "kubectl apply -f deployment-service.yaml"
                        sh "kubectl get svc"
                    }
                }
            }
        }
    }

        post {
            always {
                emailext (
                    subject: "Pipeline Status: ${JOB_NAME} ${BUILD_NUMBER}",
                    body: '''<html>
                                <body>
                                    <p>Build Status: ${BUILD_STATUS}</p>
                                    <p>Build Number: ${BUILD_NUMBER}</p>
                                    <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                                </body>
                            </html>''',
                    to: 'franciswatson9@gmail.com',
                    from: 'jenkins@example.com',
                    replyTo: 'jenkins@example.com',
                    mimeType: 'text/html'
                )
            }
        }

    
}
