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
                    echo "Identifying delta changes between last commit and latest commit"

                    // Ensure the current branch is checked out
                    bat "git checkout ${env.BRANCH_NAME}"

                    // Check if the upstream branch is set
                    def upstreamBranch = bat(script: 'git rev-parse --abbrev-ref --symbolic-full-name @{u} || echo no-upstream', returnStdout: true).trim()

                    if (upstreamBranch == 'no-upstream') {
                        echo "No upstream branch configured. Setting upstream to origin/${env.BRANCH_NAME}."
                        // Set the upstream branch to the corresponding remote branch
                        def branchExists = bat(script: "git ls-remote --exit-code --heads origin ${env.BRANCH_NAME}", returnStatus: true) == 0
                        if (!branchExists) {
                            echo "Branch ${env.BRANCH_NAME} does not exist on the remote, pushing it..."
                            bat "git push --set-upstream origin ${env.BRANCH_NAME}"
                        } else {
                            bat "git branch --set-upstream-to=origin/${env.BRANCH_NAME}"
                        }
                    }

                    // Get the list of changed files (relative paths)
                    def changedFiles = bat(script: 'git diff --name-only @{u} HEAD', returnStdout: true).trim().split("\r\n")
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
