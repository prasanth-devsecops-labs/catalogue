pipeline {
    agent {
        node {
            label 'roboshop' 
        } 
    }
    environment {
        appVersion = ""
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
        stage('Install dependencies') {
            steps {
                script{
                    sh """
                        npm install
                    """
                }
            }
        }

        stage('Build Docker image') {
            steps {
                script{
                    sh """
                        docker build -t catalogue:${appVersion} .
                    """
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

