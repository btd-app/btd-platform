/**
 * Job DSL for BTD Application Deployment Pipeline
 *
 * Creates jobs for application-only deployments (Ansible)
 */

pipelineJob('btd-platform/application-deployment') {
    displayName('BTD Platform - Application Deployment')
    description('Deploy application updates without infrastructure changes')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
        stringParam('SERVICES', 'all', 'Services to deploy (comma-separated or "all")')
        booleanParam('SKIP_TESTS', false, 'Skip test execution')
        booleanParam('SKIP_BUILD', false, 'Skip build (use existing artifacts)')
        booleanParam('RUN_MIGRATIONS', true, 'Run database migrations')
        booleanParam('ROLLING_DEPLOYMENT', true, 'Deploy services one at a time')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/btd-app/btd-shared.git')
                        credentials('btd-github-pat')
                    }
                    branches('main')
                }
            }
            scriptPath('jenkins/Jenkinsfile.application')
        }
    }

    properties {
        disableConcurrentBuilds()
        buildDiscarder {
            strategy {
                logRotator {
                    daysToKeepStr('90')
                    numToKeepStr('50')
                    artifactDaysToKeepStr('30')
                    artifactNumToKeepStr('10')
                }
            }
        }
    }
}

// Build verification job (PR checks)
multibranchPipelineJob('btd-platform/build-verification') {
    displayName('BTD Platform - Build Verification')
    description('Automated build and test verification for PRs and branches')

    branchSources {
        github {
            id('btd-app-github-verify')
            repoOwner('btd-app')
            repository('btd-shared')
            scanCredentialsId('btd-github-pat')
        }
    }

    factory {
        workflowBranchProjectFactory {
            scriptPath('jenkins/Jenkinsfile.build-verification')
        }
    }

    orphanedItemStrategy {
        discardOldItems {
            numToKeep(30)
            daysToKeep(30)
        }
    }

    triggers {
        periodicFolderTrigger {
            interval('10m')
        }
    }
}

// Service-specific deployment jobs
['auth', 'users', 'matches', 'messaging', 'notification', 'payment',
 'admin', 'analytics', 'ai', 'orchestrator'].each { service ->
    def serviceName = "btd-${service}-service"
    def runMigrations = (service == 'auth' || service == 'users')

    pipelineJob("btd-platform/deploy-${service}-service") {
        displayName("Deploy ${service.capitalize()} Service")
        description("Deploy only the ${serviceName}")

        parameters {
            choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
            booleanParam('SKIP_TESTS', false, 'Skip tests')
            booleanParam('RUN_MIGRATIONS', runMigrations, 'Run migrations')
        }

        definition {
            cps {
                script("""
                    pipeline {
                        agent any

                        stages {
                            stage('Deploy ${service.capitalize()} Service') {
                                steps {
                                    build job: 'btd-platform/application-deployment',
                                          parameters: [
                                              string(name: 'ENVIRONMENT', value: params.ENVIRONMENT),
                                              string(name: 'SERVICES', value: '${serviceName}'),
                                              booleanParam(name: 'SKIP_TESTS', value: params.SKIP_TESTS),
                                              booleanParam(name: 'SKIP_BUILD', value: false),
                                              booleanParam(name: 'RUN_MIGRATIONS', value: params.RUN_MIGRATIONS),
                                              booleanParam(name: 'ROLLING_DEPLOYMENT', value: false)
                                          ],
                                          wait: true
                                }
                            }
                        }

                        post {
                            always {
                                echo "Deployment complete: ${serviceName}"
                            }
                        }
                    }
                """)
                sandbox(true)
            }
        }
    }
}

// Hotfix deployment job
pipelineJob('btd-platform/hotfix-deployment') {
    displayName('BTD Platform - Hotfix Deployment')
    description('Emergency hotfix deployment with minimal checks')

    parameters {
        choiceParam('ENVIRONMENT', ['staging', 'production'], 'Target environment')
        stringParam('SERVICE', '', 'Service name (required)')
        stringParam('GIT_BRANCH', 'main', 'Git branch/tag/commit')
        stringParam('DESCRIPTION', '', 'Hotfix description (required)')
        booleanParam('SKIP_APPROVAL', false, 'Skip approval gate (emergency only)')
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent any

                    stages {
                        stage('Validate') {
                            steps {
                                script {
                                    if (!params.SERVICE || !params.DESCRIPTION) {
                                        error("SERVICE and DESCRIPTION are required")
                                    }
                                    echo "Hotfix Deployment: ${params.SERVICE}"
                                    echo "Description: ${params.DESCRIPTION}"
                                }
                            }
                        }

                        stage('Approval') {
                            when {
                                expression { !params.SKIP_APPROVAL }
                            }
                            steps {
                                timeout(time: 10, unit: 'MINUTES') {
                                    input message: "Deploy hotfix to ${params.ENVIRONMENT}?",
                                          ok: 'Deploy',
                                          submitter: 'admin,devops-team'
                                }
                            }
                        }

                        stage('Deploy') {
                            steps {
                                build job: 'btd-platform/application-deployment',
                                      parameters: [
                                          string(name: 'ENVIRONMENT', value: params.ENVIRONMENT),
                                          string(name: 'SERVICES', value: params.SERVICE),
                                          booleanParam(name: 'SKIP_TESTS', value: true),
                                          booleanParam(name: 'RUN_MIGRATIONS', value: false)
                                      ],
                                      wait: true
                            }
                        }
                    }

                    post {
                        always {
                            echo "Hotfix deployment complete: ${params.SERVICE}"
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}

// Rollback job
pipelineJob('btd-platform/rollback-deployment') {
    displayName('BTD Platform - Rollback Deployment')
    description('Rollback to previous deployment')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
        stringParam('DEPLOYMENT_ID', '', 'Deployment ID to rollback (leave empty for last)')
        stringParam('SERVICES', 'all', 'Services to rollback')
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent any

                    environment {
                        JENKINS_DIR = '/root/projects/btd-app/jenkins'
                    }

                    stages {
                        stage('Approval') {
                            steps {
                                timeout(time: 15, unit: 'MINUTES') {
                                    input message: "Rollback ${params.SERVICES} in ${params.ENVIRONMENT}?",
                                          ok: 'Rollback',
                                          submitter: 'admin,devops-team'
                                }
                            }
                        }

                        stage('Rollback') {
                            steps {
                                script {
                                    sh """
                                        chmod +x ${JENKINS_DIR}/scripts/rollback-deployment.sh
                                        ${JENKINS_DIR}/scripts/rollback-deployment.sh \\
                                            ${params.DEPLOYMENT_ID} \\
                                            ${params.ENVIRONMENT} \\
                                            ${params.SERVICES}
                                    """
                                }
                            }
                        }

                        stage('Verify') {
                            steps {
                                script {
                                    sh """
                                        chmod +x ${JENKINS_DIR}/scripts/post-deployment-health-check.sh
                                        ${JENKINS_DIR}/scripts/post-deployment-health-check.sh ${params.ENVIRONMENT}
                                    """
                                }
                            }
                        }
                    }

                    post {
                        success {
                            echo "✓ Rollback completed successfully"
                        }
                        failure {
                            echo "❌ Rollback failed - manual intervention required"
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}
