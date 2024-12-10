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
                checkout scm
                bat "git fetch --all" // Ensure all remotes are fetched
            }
        }

        stage('Identify Delta Changes') {
            steps {
                script {
                    echo "Identifying delta changes between the 'qa' branch and the current feature branch"
                    
                    // List files in scripts/bash for debugging
                    bat "dir ${env.WORKSPACE}\\scripts\\bash"
                    
                    // Run the validate-diff-change.sh script to get the list of changed files between 'qa' and the feature branch
                    def changedFiles = bat(script: "${env.WORKSPACE}\\scripts\\bash\\validate-diff-change.sh qa ${env.BRANCH_NAME}", returnStdout: true).trim()
                    
                    // Print changed files for debugging
                    echo "Changed files: ${changedFiles}"
                    
                    if (changedFiles.contains("No changes")) {
                        echo "No changes detected between 'qa' and ${env.BRANCH_NAME}."
                        env.CHANGED_FILES = ''
                    } else {
                        echo "Changed files: ${changedFiles}"
                        env.CHANGED_FILES = changedFiles
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                script {
                    input message: 'Do you approve deployment to the QA Org?',
                          parameters: [
                              string(defaultValue: 'yes', description: 'Approve deployment?', name: 'Approval')
                          ]
                }
            }
        }

        stage('Deploy to QA Branch') {
            steps {
                script {
                    echo "Deploying delta changes to QA branch"
                    bat "git fetch"
                    bat "git switch qa"
                    
                    // Check if CHANGE_TARGET is set
                    if (env.CHANGE_TARGET) {
                        bat "git merge ${env.CHANGE_TARGET}" // Merge PR into QA branch
                    } else {
                        error "CHANGE_TARGET is not defined. Cannot merge."
                    }
                    
                    bat "git push origin qa" // Push to the QA branch
                }
            }
        }

        stage('Deploy to QA Org') {
            steps {
                script {
                    echo "Deploying delta changes to Salesforce QA Org"
                    
                    withCredentials([string(credentialsId: 'sfdx-auth-qa', variable: 'SFDX_AUTH_URL_QA')]) {
                        // Authenticate to Salesforce QA Org
                        bat "echo ${SFDX_AUTH_URL_QA} | sfdx auth:sfdxurl:store -f -"
                    }
                    
                    // Deploy only the delta changes to the Salesforce QA Org
                    bat "sfdx force:source:deploy -p ${env.CHANGED_FILES} --targetusername ${SFDX_AUTH_URL_QA} --checkonly --testlevel RunLocalTests"
                }
            }
        }
    }
}
