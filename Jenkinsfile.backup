pipeline {
    agent {
        node {
            label 'roboshop' 
        } 
    }
    environment {
        appVersion = ""
        acc_id = "334602727445"
        region = "us-east-1"
    }
    options {
        // disableConcurrentBuilds()
        timeout(time: 5, unit: 'MINUTES')
    }
    // parameters {
    //     string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
    //     text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')
    //     booleanParam(name: 'DEPLOY', defaultValue: false, description: 'Toggle this value')
    //     choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
    //     password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')
    // }
    stages {
        stage('Read the version') {
            steps {
                script {
                    def packageJson = readJSON file : 'package.json'
                    appVersion = packageJson.version
                    echo "Building version ${appVersion}"
                }
            }
        }
        // stage('Install dependencies') {
        //     steps {
        //         script{
        //             sh """
        //                 npm install
        //             """
        //         }
        //     }
        // }
        // stage ('SonarQube Analysis'){
        //     steps {
        //         script {
        //             def scannerHome = tool name: 'sonar-8' // agent configuration
        //             withSonarQubeEnv('sonar-server') { // analysing and uploading to server
        //                 sh "${scannerHome}/bin/sonar-scanner"
        //             }
        //         }
        //     }
        // }
        // stage("Quality Gate") {
        //     steps {
        //       timeout(time: 1, unit: 'HOURS') {
        //         waitForQualityGate abortPipeline: true
        //       }
        //     }
        // }
        stage('Dependabot Alerts Check') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    script {
                        def owner = 'prasanth-devsecops-labs'
                        def repo  = 'catalogue'

                        def response = sh(
                            script: """
                                curl -s -w "\\n%{http_code}" \\
                                    -H "Authorization: Bearer ${GITHUB_TOKEN}" \\
                                    -H "Accept: application/vnd.github+json" \\
                                    -H "X-GitHub-Api-Version: 2022-11-28" \\
                                    "https://api.github.com/repos/${owner}/${repo}/dependabot/alerts?severity=high,critical&state=open&per_page=100"
                            """,
                            returnStdout: true
                        ).trim()

                        def parts      = response.tokenize('\n')
                        def httpStatus = parts[-1].trim()
                        def body       = parts[0..-2].join('\n')

                        if (httpStatus != '200') {
                            error "GitHub API call failed with HTTP ${httpStatus}. Check token permissions (security_events scope required).\nResponse: ${body}"
                        }

                        def alerts = readJSON text: body

                        if (alerts.size() == 0) {
                            echo "✅ No HIGH or CRITICAL Dependabot alerts found. Pipeline continues."
                        } else {
                            echo "🚨 Found ${alerts.size()} HIGH/CRITICAL Dependabot alert(s):"
                            alerts.each { alert ->
                                def pkg      = alert.security_vulnerability?.package?.name ?: 'unknown'
                                def severity = alert.security_advisory?.severity?.toUpperCase() ?: 'UNKNOWN'
                                def summary  = alert.security_advisory?.summary ?: 'No summary'
                                def fixedIn  = alert.security_vulnerability?.first_patched_version?.identifier ?: 'No fix available'
                                echo "  ❌ [${severity}] ${pkg} — ${summary} (Fixed in: ${fixedIn})"
                            }
                            error "Pipeline failed: ${alerts.size()} HIGH/CRITICAL Dependabot alert(s) detected."
                        }
                    }
                }
            }
        }

        stage('Build Docker image') {
            steps {
                script{
                    withAWS(credentials: 'aws-creds', region: "${region}") {
                        sh """
                            docker build -t ${acc_id}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion} .
                        """
                    }
                }
            }
        }
        stage('Trivy OS Scan') {
            steps {
                script {
                    // Generate table report
                    sh """
                        trivy image \
                            --scanners vuln \
                            --pkg-types os \
                            --severity HIGH,MEDIUM \
                            --format table \
                            --output trivy-os-report.txt \
                            --exit-code 0 \
                            ${acc_id}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}
                    """

                    // Print table to console
                    sh 'cat trivy-os-report.txt'

                    // Fail pipeline if vulnerabilities found
                    def scanResult = sh(
                        script: """
                            trivy image \
                                --scanners vuln \
                                --pkg-types os \
                                --severity HIGH,MEDIUM \
                                --format table \
                                --exit-code 1 \
                                --quiet \
                                ${acc_id}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}
                        """,
                        returnStatus: true
                    )

                    if (scanResult != 0) {
                        error "🚨 Trivy found HIGH/MEDIUM OS vulnerabilities. Pipeline failed."
                    } else {
                        echo "✅ No HIGH or MEDIUM OS vulnerabilities found. Pipeline continues."
                    }
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script{
                    withAWS(credentials: 'aws-creds', region: "${region}") {
                        sh """
                            aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${acc_id}.dkr.ecr.${region}.amazonaws.com
                            docker push ${acc_id}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}
                        """
                    }
                }
            }
        }
    }

    // post build
    post { 
        always { 
            echo 'I will always say Hello again!'
        }
        success {
            echo "pipeline success"
        }
        failure {
            echo "pipeline failure"
        }
    }
}

