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
                bat "git fetch --all" // Ensure all remotes are fetched
            }
        }

       stage('Identify Delta Changes') {
    steps {
        script {
            echo "Identifying delta changes between the last pushed commit on 'qa' branch and the new commit"

            // Fetch all branches to ensure local refs are up-to-date
            bat "git fetch origin"

            try {
                // Check if the 'qa' branch exists on the remote
                def qaBranchExists = bat(script: 'git ls-remote --heads origin qa', returnStatus: true) == 0

                if (!qaBranchExists) {
                    error "'qa' branch does not exist on the remote. Please create it first."
                }

                // Get the latest commit hash of the `qa` branch
                def qaLastCommit = bat(script: 'git rev-parse origin/qa', returnStdout: true).trim()
                echo "Last pushed commit on 'qa' branch: ${qaLastCommit}"

                // Calculate the diff between the latest `qa` branch commit and the current HEAD
                def changedFiles = bat(script: "git diff --name-only ${qaLastCommit} HEAD", returnStdout: true).trim().split("\r\n")
                
                if (changedFiles.isEmpty()) {
                    echo "No changes detected since the last commit on 'qa' branch."
                    env.CHANGED_FILES = ''
                } else {
                    echo "Changed files since last commit on 'qa' branch: ${changedFiles}"
                    env.CHANGED_FILES = changedFiles.join(" ")
                }
            } catch (Exception e) {
                error "Error identifying delta changes: ${e.message}"
            }
        }
    }
}
        // -------------------------------------------------------------------------
        // Approval Step
        // -------------------------------------------------------------------------
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
                    bat "git merge ${env.CHANGE_TARGET}" // Merge PR into QA branch
                    bat "git push origin qa"             // Push to the QA branch
                }
            }
        }

        stage('Deploy to QA Org') {
            steps {
                script {
                    echo "Deploying delta changes to Salesforce QA Org"
                    // Authenticate to Salesforce QA Org
                    bat "echo ${SFDX_AUTH_URL_QA} | sfdx auth:sfdxurl:store -f -"
                    // Deploy only the delta changes to the Salesforce QA Org
                    bat "sfdx force:source:deploy -p ${env.CHANGED_FILES} --targetusername ${SFDX_AUTH_URL_QA} --checkonly --testlevel RunLocalTests"
                }
            }
        }
    }
}
