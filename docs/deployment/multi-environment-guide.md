# Multi-Environment Deployment Guide

**Last Updated**: 2025-11-03

## Overview

BTD uses a three-environment architecture with automated deployments based on git branches:

- **Development**: Active development and testing
- **Staging**: Pre-production validation
- **Production**: Live production services

## Environment Configuration

### Branch-to-Environment Mapping

| Git Branch | Environment | Auto-Deploy | Approval Required |
|-----------|------------|-------------|-------------------|
| `develop` | Development (10.27.26.x) | ✅ Yes | No |
| `staging` | Staging (10.27.26.1xx) | ✅ Yes | No |
| `main` | Production (10.27.27.x) | Manual | ✅ Yes |

### Environment Variables

Each environment has isolated configuration managed by Ansible templates:

```bash
# Development
DATABASE_URL=postgresql://dev_[service]_user:[password]@10.27.27.70:5432/btd_[service]_dev
REDIS_URL=redis://:dev_password@10.27.27.71:6379

# Staging
DATABASE_URL=postgresql://staging_[service]_user:[password]@10.27.27.70:5432/btd_[service]_staging
REDIS_URL=redis://:staging_password@10.27.27.71:6379

# Production
DATABASE_URL=postgresql://[service]_user:[password]@10.27.27.70:5432/btd_[service]
REDIS_URL=redis://:production_password@10.27.27.71:6379
```

## Deployment Flow

### 1. Developer Workflow

```bash
# Development deployment
git checkout develop
git add .
git commit -m "feat: new feature"
git push origin develop

# Staging deployment
git checkout staging
git merge develop
git push origin staging

# Production deployment (requires approval)
git checkout main
git merge staging
git push origin main
```

### 2. Automated Pipeline

```
GitHub Push
    ↓
GitHub Webhook
    ↓
Jenkins (10.27.27.251)
    │
    ├─ Checkout branch
    ├─ Install dependencies (npm ci)
    ├─ Build (npm run build)
    ├─ Lint (npm run lint)
    ├─ Test (npm run test)
    │
    ├─ [Production Only] Manual Approval Gate
    │
    └─ Deploy via Ansible
        ↓
Ansible LXC (10.27.27.181)
    │
    ├─ Receive build artifacts via rsync
    ├─ Generate environment-specific .env
    ├─ Run Prisma migrations
    ├─ Deploy to target LXC container
    ├─ Restart systemd service
    └─ Health check verification
```

### 3. Ansible Playbook Execution

```yaml
# Simplified playbook structure
- name: Deploy BTD Service
  hosts: "{{ environment_name }}_services"
  tasks:
    - name: Create deployment directory
    - name: Copy build artifacts
    - name: Generate .env from template
    - name: Install production dependencies
    - name: Run database migrations
    - name: Restart service
    - name: Verify health endpoint
```

## Environment-Specific Features

### Development
- **Purpose**: Active feature development
- **Data**: Synthetic test data
- **Debugging**: Verbose logging enabled
- **Database**: Frequently reset/seeded
- **Monitoring**: Basic health checks

### Staging
- **Purpose**: Pre-production validation
- **Data**: Production-like data (anonymized)
- **Debugging**: Production-level logging
- **Database**: Stable, migrated before production
- **Monitoring**: Full monitoring stack

### Production
- **Purpose**: Live customer-facing services
- **Data**: Real customer data
- **Debugging**: Error-level logging only
- **Database**: Persistent with backups
- **Monitoring**: Full observability + alerting

## Rollback Procedures

### Automated Rollback

Jenkins pipeline includes automatic rollback on health check failure:

```groovy
stage('Health Check') {
    steps {
        script {
            def healthOk = sh(returnStatus: true, script: "curl -f http://${DEPLOY_IP}:${HTTP_PORT}/api/v1/health")
            if (healthOk != 0) {
                error "Health check failed - triggering rollback"
            }
        }
    }
    post {
        failure {
            sh "ansible-playbook rollback.yml -i ${INVENTORY_FILE}"
        }
    }
}
```

### Manual Rollback

```bash
# SSH to Ansible LXC
ssh root@10.27.27.181

# Run rollback playbook
cd /root/btd-infrastructure/ansible
ansible-playbook rollback-service.yml \
  -i inventory/production.yml \
  -e "service_name=btd-analytics-service" \
  -e "rollback_version=previous"
```

## Database Migrations

### Development

Migrations run automatically on every deployment:

```bash
npx prisma migrate deploy
```

### Staging

Same as development - automated migration application.

### Production

Migrations require manual approval in Jenkins pipeline:

```groovy
stage('Production Migrations') {
    when { branch 'main' }
    steps {
        input message: "Apply database migrations to PRODUCTION?",
              ok: 'Apply Migrations'
        sh "npx prisma migrate deploy"
    }
}
```

## Monitoring Deployments

### Jenkins Build Status

```bash
# Check latest build status
curl -u 'btd-user:PASSWORD' \
  'http://10.27.27.251:8080/job/btd-microservices/job/btd-analytics-service/job/develop/lastBuild/api/json'
```

### Service Health

```bash
# Development
curl http://10.27.26.84:3003/api/v1/health

# Staging
curl http://10.27.26.184:3003/api/v1/health

# Production
curl http://10.27.27.84:3003/api/v1/health
```

### Consul Service Discovery

```bash
# Check service registration
curl http://10.27.27.27:8500/v1/health/service/btd-analytics-service
```

## Troubleshooting

### Deployment Failed

1. Check Jenkins console output
2. Verify Ansible LXC connectivity
3. Check target container systemd status
4. Review service logs

### Service Not Starting

1. Check DATABASE_URL in .env
2. Verify database connectivity
3. Check Prisma migration status
4. Review systemd journal logs

### Health Check Failing

1. Verify service is listening on correct port
2. Check application logs for errors
3. Test database connectivity
4. Verify Redis connectivity

## See Also

- [Jenkins Pipeline Guide](jenkins-pipeline-guide.md)
- [Ansible Playbook Guide](ansible-playbook-guide.md)
- [Common Deployment Issues](../troubleshooting/common-deployment-issues.md)
- [Multi-Environment Database Credentials](../../credentials/MULTI-ENVIRONMENT-DATABASE-CREDENTIALS.md)
