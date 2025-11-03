# BTD Platform - Pipeline Usage Guide

Complete guide for using Jenkins pipelines to deploy the BTD platform.

**Network:** 10.27.27.0/23
**Jenkins Server:** http://10.27.27.251:8080

---

## Table of Contents

1. [Available Pipelines](#available-pipelines)
2. [Main Deployment Pipeline](#main-deployment-pipeline)
3. [Infrastructure Pipeline](#infrastructure-pipeline)
4. [Application Pipeline](#application-pipeline)
5. [Build Verification Pipeline](#build-verification-pipeline)
6. [Common Scenarios](#common-scenarios)
7. [Monitoring Deployments](#monitoring-deployments)
8. [Best Practices](#best-practices)

---

## Available Pipelines

### Pipeline Overview

| Pipeline | Purpose | Trigger | Approval Required |
|----------|---------|---------|-------------------|
| **main-deployment** | Full deployment (infra + app) | GitHub push, Manual | Production only |
| **infrastructure-deployment** | Terraform only | Manual | Production only |
| **application-deployment** | Ansible only | GitHub push, Manual | Production only |
| **build-verification** | CI checks for PRs | GitHub PR | No |
| **hotfix-deployment** | Emergency fixes | Manual | Optional |
| **rollback-deployment** | Revert deployment | Manual | Yes |

---

## Main Deployment Pipeline

**Job:** `btd-platform/main-deployment`
**Jenkinsfile:** `jenkins/Jenkinsfile`

### Purpose

Complete end-to-end deployment including:
1. Build and test all services
2. Provision infrastructure (Terraform)
3. Deploy applications (Ansible)
4. Run health checks and smoke tests

### When to Use

- **Production releases** from main branch
- **Staging deployments** from staging branch
- **Full environment refresh** in development
- **After major infrastructure changes**

### Parameters

```yaml
ENVIRONMENT:
  - development (auto-deploy)
  - staging (auto-deploy with full tests)
  - production (manual approval required)

SKIP_TESTS: false
  Description: Skip test execution (not recommended for production)

INFRASTRUCTURE_ONLY: false
  Description: Deploy infrastructure changes only

APPLICATION_ONLY: false
  Description: Deploy application only (skip Terraform)

FORCE_REBUILD: false
  Description: Force rebuild all services (ignore cache)

SERVICES_TO_DEPLOY: "all"
  Description: Comma-separated service names or "all"
  Example: "btd-auth-service,btd-users-service"
```

### Usage Examples

#### 1. Full Production Deployment

```
1. Navigate to: btd-platform/main-deployment
2. Click "Build with Parameters"
3. Select:
   - ENVIRONMENT: production
   - SKIP_TESTS: false
   - INFRASTRUCTURE_ONLY: false
   - APPLICATION_ONLY: false
   - FORCE_REBUILD: false
   - SERVICES_TO_DEPLOY: all
4. Click "Build"
5. Approve Terraform changes when prompted
6. Approve Application deployment when prompted
7. Monitor deployment progress
```

#### 2. Development Auto-Deployment

Push to `development` branch triggers automatic deployment:

```bash
git checkout development
git pull origin main
git push origin development
```

Jenkins will automatically:
- Build all services
- Run tests
- Deploy to development environment
- Send Slack notification

#### 3. Deploy Specific Services

```
Parameters:
- ENVIRONMENT: staging
- SERVICES_TO_DEPLOY: "btd-auth-service,btd-users-service"
- APPLICATION_ONLY: true
```

### Pipeline Stages

```
1. Initialization
   └─ Load environment configuration

2. Checkout
   └─ Clone repository and submodules

3. Pre-Deployment Validation
   └─ Run pre-deployment-checks.sh

4. Build & Test Services (Parallel)
   ├─ Build Auth Service
   ├─ Build Users Service
   ├─ Build Matches Service
   └─ ... (18 services total)

5. Run Tests (Parallel)
   ├─ Unit Tests
   ├─ Integration Tests
   └─ Lint & Typecheck

6. Infrastructure Provisioning (Terraform)
   ├─ Terraform Init
   ├─ Terraform Validate
   ├─ Terraform Plan
   ├─ Manual Approval (Production)
   ├─ Terraform Apply
   └─ Export Ansible Inventory

7. Application Deployment (Ansible)
   ├─ Ansible Syntax Check
   ├─ Manual Approval (Production)
   ├─ Deploy Services
   └─ Database Migrations

8. Post-Deployment Verification
   ├─ Health Checks
   └─ Smoke Tests (Production)

9. Notifications
   └─ Slack/Email notification
```

### Approval Gates

Production deployments require manual approval at:

1. **Terraform Apply:** After reviewing infrastructure plan
2. **Application Deploy:** Before deploying application changes

**Approvers:** admin, devops-team

### Rollback on Failure

If deployment fails:
1. Pipeline automatically triggers rollback script
2. Stops failed services
3. Restores previous code version
4. Redeploys services
5. Verifies rollback success
6. Sends failure notification

---

## Infrastructure Pipeline

**Job:** `btd-platform/infrastructure-deployment`
**Jenkinsfile:** `jenkins/Jenkinsfile.infrastructure`

### Purpose

Deploy infrastructure changes using Terraform:
- Create/modify LXC containers
- Update network configurations
- Scale resources
- Modify Proxmox settings

### When to Use

- **Infrastructure-only changes** (no code deployment)
- **Scaling operations** (add/remove containers)
- **Network modifications**
- **Resource allocation changes**

### Parameters

```yaml
ENVIRONMENT: [development, staging, production]

DRY_RUN: false
  Description: Run terraform plan only (no apply)

DESTROY: false
  Description: DANGER - Destroy infrastructure (requires approval)
```

### Usage Examples

#### 1. Plan Infrastructure Changes

```
Parameters:
- ENVIRONMENT: production
- DRY_RUN: true
- DESTROY: false

Result: Shows Terraform plan without applying changes
```

#### 2. Apply Infrastructure Changes

```
Parameters:
- ENVIRONMENT: production
- DRY_RUN: false
- DESTROY: false

Steps:
1. Review Terraform plan output
2. Approve changes (production only)
3. Apply changes
4. Update Ansible inventory
```

#### 3. Destroy Environment (DANGEROUS)

```
Parameters:
- ENVIRONMENT: development
- DRY_RUN: false
- DESTROY: true

WARNING: This will destroy all infrastructure!
Use only for:
- Decommissioning development environments
- Complete environment rebuild
- Never use on production!
```

### Pipeline Stages

```
1. Initialization
2. Checkout
3. Pre-Deployment Checks
4. Terraform Init
5. Terraform Validate
6. Terraform Plan
7. Manual Approval (Production)
8. Terraform Apply
9. Export Outputs
10. Verify Infrastructure
```

---

## Application Pipeline

**Job:** `btd-platform/application-deployment`
**Jenkinsfile:** `jenkins/Jenkinsfile.application`

### Purpose

Deploy application updates without infrastructure changes:
- Code deployments
- Configuration updates
- Hotfixes
- Service restarts

### When to Use

- **Code-only deployments**
- **Configuration changes**
- **Quick updates** without infrastructure changes
- **Service-specific deployments**

### Parameters

```yaml
ENVIRONMENT: [development, staging, production]

SERVICES: "all"
  Description: Services to deploy (comma-separated or "all")

SKIP_TESTS: false
  Description: Skip test execution

SKIP_BUILD: false
  Description: Skip build (use existing artifacts)

RUN_MIGRATIONS: true
  Description: Run database migrations

ROLLING_DEPLOYMENT: true
  Description: Deploy services one at a time (reduces downtime)
```

### Usage Examples

#### 1. Deploy All Services

```
Parameters:
- ENVIRONMENT: production
- SERVICES: all
- SKIP_TESTS: false
- RUN_MIGRATIONS: true
- ROLLING_DEPLOYMENT: true
```

#### 2. Deploy Single Service

```
Parameters:
- ENVIRONMENT: staging
- SERVICES: "btd-auth-service"
- SKIP_TESTS: false
- RUN_MIGRATIONS: false
- ROLLING_DEPLOYMENT: false
```

#### 3. Quick Hotfix (Skip Tests)

```
Parameters:
- ENVIRONMENT: production
- SERVICES: "btd-payment-service"
- SKIP_TESTS: true
- SKIP_BUILD: false
- RUN_MIGRATIONS: false
- ROLLING_DEPLOYMENT: true
```

### Rolling Deployment

When enabled, services are deployed one at a time:
- **Minimizes downtime**
- **Allows early failure detection**
- **Easier rollback**

Deployment order:
1. Infrastructure services (if any)
2. Core services (auth, users)
3. Business services
4. Auxiliary services

---

## Build Verification Pipeline

**Job:** `btd-platform/build-verification`
**Jenkinsfile:** `jenkins/Jenkinsfile.build-verification`

### Purpose

Automated CI checks for pull requests:
- Build all services
- Run tests
- Check code quality
- Verify dependencies

### Trigger

Automatically triggered by:
- **Pull request opened**
- **Pull request synchronized** (new commits)
- **Pull request reopened**

### Pipeline Stages

```
1. Checkout PR branch
2. Check dependencies
3. Build services (parallel)
4. Run tests (parallel)
   ├─ Unit tests
   ├─ Lint
   ├─ TypeScript check
   └─ Proto validation
5. Security scan
6. Generate build report
7. Update GitHub PR status
```

### GitHub Status Checks

Build verification updates PR with:
- ✅ **Success:** All checks passed
- ❌ **Failure:** Build or tests failed
- ⚠️ **Unstable:** Build passed with warnings

---

## Common Scenarios

### Scenario 1: Regular Production Release

```bash
# 1. Merge feature branch to staging
git checkout staging
git merge feature/new-feature
git push origin staging

# 2. Verify staging deployment succeeds (automatic)

# 3. Merge staging to main
git checkout main
git merge staging
git push origin main

# 4. Monitor main deployment pipeline
#    - Approve Terraform changes (if any)
#    - Approve application deployment
#    - Verify smoke tests pass

# 5. Confirm in Slack channel
```

### Scenario 2: Hotfix Deployment

```bash
# 1. Create hotfix branch
git checkout -b hotfix/critical-bug main

# 2. Make fix and test locally
npm run test

# 3. Push hotfix
git push origin hotfix/critical-bug

# 4. Use hotfix-deployment job
Job: btd-platform/hotfix-deployment
Parameters:
  - ENVIRONMENT: production
  - SERVICE: btd-payment-service
  - GIT_BRANCH: hotfix/critical-bug
  - DESCRIPTION: "Fix payment processing bug"

# 5. Merge hotfix to main after verification
git checkout main
git merge hotfix/critical-bug
git push origin main
```

### Scenario 3: Infrastructure Scaling

```bash
# 1. Update Terraform configuration
vim terraform/main.tf
# Add new container or modify resources

# 2. Commit changes
git add terraform/
git commit -m "Scale: Add new messaging service container"
git push origin main

# 3. Run infrastructure-deployment job
Job: btd-platform/infrastructure-deployment
Parameters:
  - ENVIRONMENT: production
  - DRY_RUN: false

# 4. Verify new infrastructure
# 5. Run application-deployment to deploy to new containers
```

### Scenario 4: Rollback Failed Deployment

```bash
# If deployment fails automatically:
# - Jenkins runs rollback-deployment.sh automatically
# - Previous version is restored
# - Services are restarted
# - Notification sent

# For manual rollback:
Job: btd-platform/rollback-deployment
Parameters:
  - ENVIRONMENT: production
  - DEPLOYMENT_ID: [leave empty for last]
  - SERVICES: all

# Approve rollback when prompted
```

### Scenario 5: Database Migration

```bash
# 1. Create migration in your service
cd btd-auth-service
npx prisma migrate dev --name add_new_field

# 2. Test migration locally
npx prisma migrate status

# 3. Commit migration files
git add prisma/migrations/
git commit -m "Migration: Add new field to User model"
git push origin main

# 4. Deploy with migrations enabled
Job: btd-platform/application-deployment
Parameters:
  - RUN_MIGRATIONS: true
  - SERVICES: "btd-auth-service"

# 5. Verify migration applied
# Check service logs for migration success
```

---

## Monitoring Deployments

### 1. Jenkins Console Output

```
Navigate to build > Console Output

Watch for:
- ✓ Green checkmarks (success)
- ✗ Red X marks (failure)
- ⚠ Yellow warnings (non-critical issues)
```

### 2. Blue Ocean View

```
Navigate to build > Open Blue Ocean

Visual pipeline view with:
- Stage progress
- Parallel execution visualization
- Time per stage
- Logs per stage
```

### 3. Slack Notifications

Deployment notifications sent to `#btd-deployments`:

```
✅ BTD Platform Deployment Successful
- Environment: production
- Build: #42
- Deployment ID: 42-prod-20251010-143025
- Commit: abc12345

❌ BTD Platform Deployment Failed
- Environment: staging
- Build: #43
- Action: Automatic rollback initiated
- View logs: [link]
```

### 4. Service Health Dashboard

After deployment:

```bash
# Run health check manually
cd /root/projects/btd-app/jenkins/scripts
./post-deployment-health-check.sh production
```

### 5. Consul Service Discovery

```bash
# Check service registration
curl http://10.27.27.27:8500/v1/agent/services | jq

# Check service health
curl http://10.27.27.27:8500/v1/health/service/btd-auth-service
```

---

## Best Practices

### 1. Development Workflow

```
feature branch → PR → CI checks → staging → production
```

### 2. Always Test in Staging First

- **Never skip staging** for production deployments
- Verify full functionality in staging
- Run smoke tests manually if needed

### 3. Use Rolling Deployments

- Enable `ROLLING_DEPLOYMENT: true` for production
- Reduces downtime
- Easier to identify problematic service

### 4. Monitor After Deployment

- Check Slack notifications
- Verify service health endpoints
- Review service logs for errors
- Monitor error rates in production

### 5. Tag Releases

```bash
# Tag production releases
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

### 6. Document Changes

- Update CHANGELOG.md
- Document breaking changes
- Update deployment notes

### 7. Deployment Windows

Production deployments:
- **Preferred:** Tuesday-Thursday, 10 AM - 2 PM
- **Avoid:** Friday afternoons, weekends, holidays
- **Emergency only:** Outside deployment windows

### 8. Communication

Before production deployment:
- Notify team in Slack
- Check for ongoing incidents
- Ensure team availability for support

---

## Troubleshooting Deployments

### Build Fails

```
1. Check console output for error
2. Review specific service build logs
3. Verify dependencies are correct
4. Check for TypeScript errors
5. Test build locally
```

### Terraform Fails

```
1. Review Terraform plan output
2. Check Proxmox API connectivity
3. Verify resource availability
4. Check state lock (might be stuck)
5. Review Terraform logs
```

### Ansible Fails

```
1. Check SSH connectivity to containers
2. Verify Ansible inventory is correct
3. Review service logs on containers
4. Check disk space on containers
5. Verify systemd service files
```

### Health Checks Fail

```
1. Check service logs: journalctl -u btd-*.service
2. Verify database connectivity
3. Check Redis connectivity
4. Review Consul service registration
5. Test endpoints manually
```

---

## Next Steps

1. ✅ Review available pipelines
2. ✅ Test deployment in development
3. ✅ Set up Slack notifications
4. ✅ Configure GitHub webhooks
5. ✅ Run first staging deployment
6. ✅ Document any custom procedures

---

**Last Updated:** 2025-10-10
**Version:** 1.0
**Maintained by:** BTD DevOps Team
