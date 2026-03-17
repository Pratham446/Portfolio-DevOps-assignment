pipeline {
    agent any

    environment {
        PROJECT_NAME = 'devsecops-app'
        TRIVY_REPORT = 'trivy-report.txt'
        AWS_DEFAULT_REGION = 'ap-south-1'
    }

    stages {

        // ─────────────────────────────────────────
        // STAGE 1: Checkout
        // ─────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '============================================'
                echo ' STAGE 1: Checking out source code...'
                echo '============================================'
                checkout scm
                echo '✅ Source code checked out successfully'
                sh 'ls -la'
            }
        }

        // ─────────────────────────────────────────
stage('Infrastructure Security Scan') {
    steps {
        echo '============================================'
        echo ' STAGE 2: Running Trivy Scan...'
        echo '============================================'

        sh '''
        docker run --rm -v $WORKSPACE:/workspace aquasec/trivy:latest \
            config /workspace/terraform \
            --severity HIGH,CRITICAL \
            --exit-code 1 \
            --quiet | tee trivy-report.txt
        '''
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
        }
        failure {
            echo '❌ Trivy scan failed: HIGH/CRITICAL vulnerabilities found!'
        }
        success {
            echo '✅ No HIGH/CRITICAL vulnerabilities found'
        }
    }
}
        // ─────────────────────────────────────────
        // STAGE 3: Terraform Plan (WITH AWS CREDS)
        // ─────────────────────────────────────────
        stage('Terraform Plan') {
            steps {
                echo '============================================'
                echo ' STAGE 3: Running Terraform Plan...'
                echo '============================================'

                dir('terraform') {

                    // 🔥 THIS IS WHERE withCredentials IS USED
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds'
                    ]]) {

                        sh '''
                            export AWS_DEFAULT_REGION=ap-south-1
                            terraform init -input=false
                            terraform validate
                            terraform plan -input=false -out=tfplan
                        '''
                    }
                }
            }
            post {
                success {
                    echo '✅ Terraform plan completed successfully'
                }
                failure {
                    echo '❌ Terraform plan failed — check configuration'
                }
            }
        }
    }

    post {
        success {
            echo '============================================'
            echo '✅ PIPELINE PASSED — All stages completed!'
            echo '============================================'
        }
        failure {
            echo '============================================'
            echo '❌ PIPELINE FAILED — Check logs above'
            echo '============================================'
        }
        always {
            echo "📦 Build #${BUILD_NUMBER} finished at ${new Date()}"
        }
    }
}
