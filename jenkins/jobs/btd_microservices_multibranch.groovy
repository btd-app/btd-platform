/**
 * Job DSL for BTD Microservices - 18 Independent Multibranch Pipelines
 *
 * Each service gets its own multibranch pipeline job.
 * Push to individual service repo triggers ONLY that service deployment.
 * NO cross-service deployment triggers.
 */

// Define all 18 microservices with their deployment details
def microservices = [
    [
        name: 'btd-auth-service',
        displayName: 'Auth Service',
        ip: '10.27.27.82',
        httpPort: 3005,
        grpcPort: 50051,
        hasMigrations: true,
        description: 'Authentication and session management service'
    ],
    [
        name: 'btd-users-service',
        displayName: 'Users Service',
        ip: '10.27.27.86',
        httpPort: 3006,
        grpcPort: 50052,
        hasMigrations: true,
        description: 'User profile and account management service'
    ],
    [
        name: 'btd-permission-service',
        displayName: 'Permission Service',
        ip: '10.27.27.94',
        httpPort: 3014,
        grpcPort: 50063,
        hasMigrations: true,
        description: 'Role-based access control and permissions service'
    ],
    [
        name: 'btd-analytics-service',
        displayName: 'Analytics Service',
        ip: '10.27.27.84',
        httpPort: 3007,
        grpcPort: 50053,
        hasMigrations: false,
        description: 'Analytics and metrics collection service'
    ],
    [
        name: 'btd-messaging-service',
        displayName: 'Messaging Service',
        ip: '10.27.27.88',
        httpPort: 3008,
        grpcPort: 50054,
        hasMigrations: true,
        description: 'Real-time messaging and chat service'
    ],
    [
        name: 'btd-notification-service',
        displayName: 'Notification Service',
        ip: '10.27.27.89',
        httpPort: 3009,
        grpcPort: 50055,
        hasMigrations: false,
        description: 'Push notifications and email service'
    ],
    [
        name: 'btd-payment-service',
        displayName: 'Payment Service',
        ip: '10.27.27.90',
        httpPort: 3010,
        grpcPort: 50056,
        hasMigrations: true,
        description: 'Payment processing and subscription management'
    ],
    [
        name: 'btd-admin-service',
        displayName: 'Admin Service',
        ip: '10.27.27.91',
        httpPort: 3011,
        grpcPort: 50057,
        hasMigrations: false,
        description: 'Administrative dashboard and tools service'
    ],
    [
        name: 'btd-ai-service',
        displayName: 'AI Service',
        ip: '10.27.27.89',
        httpPort: 3030,
        grpcPort: 50058,
        hasMigrations: false,
        description: 'AI-powered features and recommendations'
    ],
    [
        name: 'btd-job-processing-service',
        displayName: 'Job Processing Service',
        ip: '10.27.27.92',
        httpPort: 3012,
        grpcPort: 50059,
        hasMigrations: false,
        description: 'Background job processing and task queue'
    ],
    [
        name: 'btd-location-service',
        displayName: 'Location Service',
        ip: '10.27.27.93',
        httpPort: 3013,
        grpcPort: 50060,
        hasMigrations: false,
        description: 'Geolocation and proximity services'
    ],
    [
        name: 'btd-matches-service',
        displayName: 'Matches Service',
        ip: '10.27.27.83',
        httpPort: 3001,
        grpcPort: 50061,
        hasMigrations: true,
        description: 'Matchmaking algorithm and user matching'
    ],
    [
        name: 'btd-moderation-service',
        displayName: 'Moderation Service',
        ip: '10.27.27.85',
        httpPort: 3002,
        grpcPort: 50062,
        hasMigrations: false,
        description: 'Content moderation and safety features'
    ],
    [
        name: 'btd-travel-service',
        displayName: 'Travel Service',
        ip: '10.27.27.95',
        httpPort: 3015,
        grpcPort: 50064,
        hasMigrations: false,
        description: 'Travel booking and itinerary management'
    ],
    [
        name: 'btd-video-call-service',
        displayName: 'Video Call Service',
        ip: '10.27.27.96',
        httpPort: 3016,
        grpcPort: 50065,
        hasMigrations: false,
        description: 'Video calling and WebRTC coordination'
    ],
    [
        name: 'btd-orchestrator',
        displayName: 'API Orchestrator',
        ip: '10.27.27.87',
        httpPort: 9130,
        grpcPort: 50066,
        hasMigrations: false,
        description: 'API gateway and service orchestration'
    ],
    [
        name: 'btd-file-processing',
        displayName: 'File Processing Service',
        ip: '10.27.27.97',
        httpPort: 3017,
        grpcPort: 50067,
        hasMigrations: false,
        description: 'File upload and media processing service'
    ],
    [
        name: 'btd-match-request-limits-service',
        displayName: 'Match Request Limits Service',
        ip: '10.27.27.80',
        httpPort: 3018,
        grpcPort: 50068,
        hasMigrations: false,
        description: 'Rate limiting for match requests'
    ]
]

// Create folder for all microservice jobs
folder('btd-microservices') {
    displayName('BTD Microservices')
    description('Independent deployment pipelines for each BTD microservice')
}

// Create multibranch pipeline for each microservice
microservices.each { service ->
    multibranchPipelineJob("btd-microservices/${service.name}") {
        displayName("${service.displayName}")
        description("""
            ${service.description}

            Deployment Target: ${service.ip}
            HTTP Port: ${service.httpPort}
            gRPC Port: ${service.grpcPort}
            Database Migrations: ${service.hasMigrations ? 'Yes' : 'No'}

            IMPORTANT: This job deploys ONLY ${service.name}.
            It does NOT trigger other service deployments.
        """.stripIndent())

        // Branch sources - GitHub repository
        branchSources {
            github {
                id("${service.name}-github-source")
                repoOwner('btd-app')
                repository(service.name)
                scanCredentialsId('btd-github-pat')

                // Build strategies
                buildStrategies {
                    buildRegularBranches()
                    buildChangeRequests {
                        ignoreTargetOnlyChanges(true)
                        ignoreUntrustedChanges(false)
                    }
                    buildTags {
                        atLeastDays('0')
                        atMostDays('7')
                    }
                }

                // Discover branches
                traits {
                    gitHubBranchDiscovery {
                        strategyId(1) // Exclude branches filed as PRs
                    }
                    gitHubPullRequestDiscovery {
                        strategyId(1) // Merging the pull request with current target branch
                    }
                    gitHubForkDiscovery {
                        strategyId(1)
                        trust {
                            gitHubTrustPermissions()
                        }
                    }
                    headWildcardFilter {
                        includes('main develop staging feature/* hotfix/*')
                        excludes('')
                    }
                    cleanBeforeCheckout()
                    cleanAfterCheckout()
                    pruneStaleBranch()
                }
            }
        }

        // Jenkinsfile location
        factory {
            workflowBranchProjectFactory {
                scriptPath('Jenkinsfile')
            }
        }

        // Branch indexing triggers
        triggers {
            periodicFolderTrigger {
                interval('5m') // Check for new branches/PRs every 5 minutes
            }
        }

        // Orphaned item strategy
        orphanedItemStrategy {
            discardOldItems {
                numToKeep(20)
                daysToKeep(30)
            }
        }

        // Properties
        properties {
            folderLibraries {
                libraries {
                    libraryConfiguration {
                        name('btd-shared-library')
                        retriever {
                            modernSCM {
                                scm {
                                    git {
                                        remote('https://github.com/btd-app/btd-shared.git')
                                        credentialsId('btd-github-pat')
                                    }
                                }
                            }
                        }
                        defaultVersion('main')
                        implicit(false)
                        allowVersionOverride(true)
                    }
                }
            }
        }

        // Configure pipeline properties
        configure { node ->
            node / 'properties' / 'org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig' {
                dockerLabel('nodejs')
                registry()
            }
        }
    }
}

// Create a view to organize all microservice jobs
listView('btd-microservices/All Services') {
    description('All BTD microservice deployment pipelines')
    jobs {
        microservices.each { service ->
            name("btd-microservices/${service.name}")
        }
    }
    columns {
        status()
        weather()
        name()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
    recurse(true)
}

// Create categorized views
def viewCategories = [
    'Core Services': ['btd-auth-service', 'btd-users-service', 'btd-permission-service', 'btd-orchestrator'],
    'Business Logic': ['btd-matches-service', 'btd-messaging-service', 'btd-travel-service', 'btd-payment-service'],
    'Support Services': ['btd-notification-service', 'btd-analytics-service', 'btd-ai-service', 'btd-job-processing-service'],
    'Infrastructure': ['btd-location-service', 'btd-moderation-service', 'btd-video-call-service', 'btd-file-processing', 'btd-admin-service', 'btd-match-request-limits-service']
]

viewCategories.each { categoryName, serviceNames ->
    listView("btd-microservices/${categoryName}") {
        description("${categoryName} deployment pipelines")
        jobs {
            serviceNames.each { serviceName ->
                name("btd-microservices/${serviceName}")
            }
        }
        columns {
            status()
            weather()
            name()
            lastSuccess()
            lastFailure()
            lastDuration()
            buildButton()
        }
        recurse(true)
    }
}

// Summary statistics dashboard job
pipelineJob('btd-microservices/deployment-dashboard') {
    displayName('Deployment Dashboard')
    description('Overview of all microservice deployment statuses')

    definition {
        cps {
            script('''
                pipeline {
                    agent any

                    stages {
                        stage('Collect Status') {
                            steps {
                                script {
                                    def services = [
                                        'btd-auth-service', 'btd-users-service', 'btd-permission-service',
                                        'btd-analytics-service', 'btd-messaging-service', 'btd-notification-service',
                                        'btd-payment-service', 'btd-admin-service', 'btd-ai-service',
                                        'btd-job-processing-service', 'btd-location-service', 'btd-matches-service',
                                        'btd-moderation-service', 'btd-travel-service', 'btd-video-call-service',
                                        'btd-orchestrator', 'btd-file-processing', 'btd-match-request-limits-service'
                                    ]

                                    echo "=== BTD Microservices Deployment Status ==="
                                    echo ""

                                    services.each { service ->
                                        def jobPath = "btd-microservices/${service}"
                                        try {
                                            def job = Jenkins.instance.getItemByFullName(jobPath)
                                            if (job) {
                                                echo "${service}: CONFIGURED"
                                            } else {
                                                echo "${service}: NOT FOUND"
                                            }
                                        } catch (Exception e) {
                                            echo "${service}: ERROR - ${e.message}"
                                        }
                                    }

                                    echo ""
                                    echo "=== End of Report ==="
                                }
                            }
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}
