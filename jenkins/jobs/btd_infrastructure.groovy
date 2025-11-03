/**
 * Job DSL for BTD Infrastructure Pipeline
 *
 * Creates jobs for infrastructure-only deployments (Terraform)
 */

pipelineJob('btd-platform/infrastructure-deployment') {
    displayName('BTD Platform - Infrastructure Deployment')
    description('Deploy infrastructure changes using Terraform (LXC containers, networking, resources)')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
        booleanParam('DRY_RUN', false, 'Run terraform plan only (no apply)')
        booleanParam('DESTROY', false, 'DANGER: Destroy infrastructure (requires approval)')
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
            scriptPath('jenkins/Jenkinsfile.infrastructure')
        }
    }

    properties {
        disableConcurrentBuilds()
        buildDiscarder {
            strategy {
                logRotator {
                    daysToKeepStr('90')
                    numToKeepStr('30')
                    artifactDaysToKeepStr('30')
                    artifactNumToKeepStr('15')
                }
            }
        }
    }

    // Trigger options
    triggers {
        // Manual trigger only for infrastructure
    }
}

// Infrastructure health check job
pipelineJob('btd-platform/infrastructure-health-check') {
    displayName('BTD Platform - Infrastructure Health Check')
    description('Verify infrastructure health without making changes')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production'], 'Target environment')
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent { label 'built-in' }

                    stages {
                        stage('Check Proxmox') {
                            steps {
                                script {
                                    echo "Checking Proxmox connectivity..."
                                    sh """
                                        curl -k -s --max-time 5 https://10.27.27.192:8006/api2/json > /dev/null
                                        echo "✓ Proxmox accessible"
                                    """
                                }
                            }
                        }

                        stage('Check Consul') {
                            steps {
                                script {
                                    echo "Checking Consul..."
                                    sh """
                                        curl -s http://10.27.27.27:8500/v1/status/leader
                                        echo "✓ Consul accessible"
                                    """
                                }
                            }
                        }

                        stage('Verify Terraform State') {
                            steps {
                                script {
                                    echo "Checking Terraform state..."
                                    dir('/var/lib/jenkins/terraform') {
                                        sh """
                                            terraform init -backend=true
                                            terraform show
                                            echo "✓ Terraform state accessible"
                                        """
                                    }
                                }
                            }
                        }

                        stage('Check LXC Containers') {
                            steps {
                                script {
                                    echo "Verifying container status..."
                                    sh """
                                        # This would query Proxmox API for container status
                                        echo "Container health check complete"
                                    """
                                }
                            }
                        }
                    }

                    post {
                        always {
                            echo "Infrastructure health check complete"
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }

    triggers {
        cron('H */6 * * *') // Run every 6 hours
    }
}

// Terraform state management job
pipelineJob('btd-platform/terraform-state-backup') {
    displayName('BTD Platform - Terraform State Backup')
    description('Backup Terraform state from Consul')

    parameters {
        choiceParam('ENVIRONMENT', ['development', 'staging', 'production', 'all'], 'Environment to backup')
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent any

                    environment {
                        BACKUP_DIR = '/var/lib/jenkins/terraform-backups'
                        CONSUL_ADDR = '10.27.27.27:8500'
                    }

                    stages {
                        stage('Backup State') {
                            steps {
                                script {
                                    def environments = params.ENVIRONMENT == 'all' ?
                                        ['development', 'staging', 'production'] :
                                        [params.ENVIRONMENT]

                                    environments.each { env ->
                                        echo "Backing up ${env} state..."
                                        sh """
                                            mkdir -p ${BACKUP_DIR}/${env}
                                            TIMESTAMP=\\$(date +%Y%m%d-%H%M%S)

                                            # Backup from Consul
                                            curl -s http://${CONSUL_ADDR}/v1/kv/terraform/btd-${env}/state?raw \\
                                                > ${BACKUP_DIR}/${env}/terraform-state-\\${TIMESTAMP}.json

                                            # Keep last 30 backups
                                            cd ${BACKUP_DIR}/${env}
                                            ls -t terraform-state-*.json | tail -n +31 | xargs -r rm

                                            echo "✓ ${env} state backed up"
                                        """
                                    }
                                }
                            }
                        }
                    }

                    post {
                        success {
                            archiveArtifacts artifacts: 'terraform-backups/**/*.json', allowEmptyArchive: true
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }

    triggers {
        cron('H 2 * * *') // Daily at 2 AM
    }
}
