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
                sh "mvn compile"
            }
        }
        stage ('Unit Test') {
            steps{
                sh "mvn test -DskipTests=true"
            }
        }

        stage ('Sonar Analysis') {
            steps{
                sh ''' mvn sonar:sonar -Dsonar.url=http://192.168.56.110:9000/ -Dsonar.login=sqp_15b95481ef0537eee470052de34a5b6ec7a82d56 -Dsonar.projectKey=secret-santa \
                   -Dsonar.projectName=secret-santa -Dsonar.java.binaries=. '''
                    
            }
        }
        stage ('Owasp Check') {
            steps{
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'DC'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage ('Maven Build') {
            steps{
                sh "mvn package -DskipTests=True"
            }
        }
        stage ('Nexus Deploy') {
            steps {
                withMaven(globalMavenSettingsConfig: 'global-maven', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh "mvn deploy -DskipTests=true"
                }
            }
            
        }
        stage ('Docker Build') {
            steps{
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker build -t santagenerator:v1 ."
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
        stage ('Docker Push') {
            steps{
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker tag santagenerator frawatson/santagenerator:v1"
                        sh "docker push frawatson/santagenerator:v1"
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
