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
        // STAGE 2: Infrastructure Security Scan
        // ─────────────────────────────────────────
        stage('Infrastructure Security Scan') {
            steps {
                echo '============================================'
                echo ' STAGE 2: Running Trivy Security Scan...'
                echo '============================================'

                script {
                    def scanResult = sh(
                        script: """
                            trivy config ./terraform \
                            --severity LOW,MEDIUM,HIGH,CRITICAL \
                            --exit-code 0 \
                            --format table \
                            2>&1 | tee ${TRIVY_REPORT}
                        """,
                        returnStdout: true
                    ).trim()

                    echo scanResult

                    def criticalCount = sh(
                        script: "grep -c 'CRITICAL' ${TRIVY_REPORT} || true",
                        returnStdout: true
                    ).trim().toInteger()

                    def highCount = sh(
                        script: "grep -c 'HIGH' ${TRIVY_REPORT} || true",
                        returnStdout: true
                    ).trim().toInteger()

                    echo '--------------------------------------------'
                    echo "🔍 Scan Summary:"
                    echo "   CRITICAL issues: ${criticalCount}"
                    echo "   HIGH issues    : ${highCount}"
                    echo '--------------------------------------------'

                    if (criticalCount > 0) {
                        error("❌ Pipeline failed: ${criticalCount} CRITICAL vulnerabilities found!")
                    } else {
                        echo '✅ No CRITICAL vulnerabilities found. Proceeding...'
                    }
                }
            }
            post {
                always {
                    echo '📄 Trivy scan report saved'
                    archiveArtifacts artifacts: "${TRIVY_REPORT}", allowEmptyArchive: true
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
