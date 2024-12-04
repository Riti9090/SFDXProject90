import groovy.json.JsonSlurperClassic

pipeline {
    agent any
    environment {
        // Salesforce CLI Authentication for different environments
        SFDX_AUTH_URL_QA = credentials('sfdx-auth-qa')    // Salesforce org for QA
        SFDX_AUTH_URL_DEV = credentials('sfdx-auth-dev')   // Salesforce org for DEV
        SFDX_AUTH_URL_PROD = credentials('sfdx-auth-prod')  // Salesforce org for Production
     }
    stages {
        stage('Checkout') {
            steps {
                // Checkout code from the branch (PR branch)
                checkout scm
            }
        }
    stage('Identify Delta Changes') {
            steps {
                script {
                    // Identify the changes between the latest commit and the last commit
                    echo "Identifying delta changes between last commit and latest commit"
                    // Get the list of changed files (relative paths)
                    def changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim().split("\n")
                    echo "Changed files: ${changedFiles}"

                    // Store the changed files as an environment variable for later stages
                    env.CHANGED_FILES = changedFiles.join(" ")
                }
            }
        }

     // -------------------------------------------------------------------------
     // Approval Step
    // -------------------------------------------------------------------------
            stage('Approval') {
                input message: 'Do you approve deployment to the QA Org?',
                      parameters: [
                          string(defaultValue: 'yes', description: 'Approve deployment?', name: 'Approval')
                      ]
            }    

    stage('Deploy to QA Branch') {
            steps {
                script {
                    // Checkout and deploy only delta changes to QA branch
                    echo "Deploying delta changes to QA branch"
                    sh "git checkout qa"
                    sh "git merge ${env.CHANGE_TARGET}" // Merge PR into QA branch
                    sh "git push origin qa"             // Push to the QA branch
                }
            }
        }
    stage('Deploy to QA Branch') {
            steps {
                script {
                    // Checkout and deploy only delta changes to QA branch
                    echo "Deploying delta changes to QA branch"
                    sh "git checkout qa"
                    sh "git merge ${env.CHANGE_TARGET}" // Merge PR into QA branch
                    sh "git push origin qa"             // Push to the QA branch
                }
            }
        }
    