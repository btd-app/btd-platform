/**
 * Job DSL for BTD Main Deployment Pipeline
 *
 * Creates a multi-branch pipeline job for the main BTD deployment
 * Triggered by GitHub webhooks and manual builds
 */

multibranchPipelineJob('btd-platform/main-deployment') {
    displayName('BTD Platform - Main Deployment')
    description('Complete BTD platform deployment: build, test, infrastructure, and application')

    branchSources {
        github {
            id('btd-app-github')
            repoOwner('btd-app')
            repository('btd-shared')

            // Use GitHub credentials
            scanCredentialsId('btd-github-pat')
        }
    }

    // Use Jenkinsfile from repository
    factory {
        workflowBranchProjectFactory {
            scriptPath('jenkins/Jenkinsfile')
        }
    }

    // Orphan branch strategy
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(20)
            daysToKeep(90)
        }
    }

    // Configure scan triggers
    configure { node ->
        node / triggers / 'com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger' {
            spec('H/15 * * * *')
            interval(900000)
        }
    }
}

// Create parameter-based job for manual deployments
pipelineJob('btd-platform/manual-deployment') {
    displayName('BTD Platform - Manual Deployment')
    description('Manual deployment with custom parameters')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
        stringParam('GIT_BRANCH', 'main', 'Git branch to deploy')
        booleanParam('SKIP_TESTS', false, 'Skip test execution')
        booleanParam('INFRASTRUCTURE_ONLY', false, 'Deploy infrastructure only')
        booleanParam('APPLICATION_ONLY', false, 'Deploy application only')
        booleanParam('FORCE_REBUILD', false, 'Force rebuild all services')
        stringParam('SERVICES_TO_DEPLOY', 'all', 'Services to deploy (comma-separated or "all")')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/btd-app/btd-shared.git')
                        credentials('btd-github-pat')
                    }
                    branches('$GIT_BRANCH')
                }
            }
            scriptPath('jenkins/Jenkinsfile')
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
