# BTD Platform - Jenkins CI/CD Infrastructure

Complete Jenkins pipeline infrastructure for automated deployment of the BTD platform across 24 LXC containers.

**Jenkins Server:** 10.27.27.251
**Network:** 10.27.27.0/23
**Deployment Target:** Proxmox infrastructure with 6 infrastructure + 18 service containers

---

## Overview

This directory contains production-ready Jenkins CI/CD pipelines that orchestrate:
- **Infrastructure provisioning** using Terraform
- **Application deployment** using Ansible
- **Automated testing** and quality checks
- **Health verification** and smoke tests
- **Automated rollback** on failures
- **Multi-environment** support (dev, staging, production)

---

## Directory Structure

```
jenkins/
├── Jenkinsfile                              # Main deployment pipeline
├── Jenkinsfile.infrastructure               # Terraform-only pipeline
├── Jenkinsfile.application                  # Ansible-only pipeline
├── Jenkinsfile.build-verification           # PR validation pipeline
├── jobs/
│   ├── btd-main-deployment.groovy          # Job DSL for main pipeline
│   ├── btd-infrastructure.groovy           # Job DSL for infrastructure
│   └── btd-application.groovy              # Job DSL for application
├── scripts/
│   ├── pre-deployment-checks.sh            # Pre-deployment validation
│   ├── post-deployment-health-check.sh     # Health verification
│   ├── rollback-deployment.sh              # Automated rollback
│   ├── smoke-tests.sh                      # Functionality tests
│   └── generate-ansible-inventory.py       # Terraform → Ansible inventory
├── config/
│   ├── credentials.example.yml             # Credential template
│   └── webhook-config.json                 # GitHub webhook config
└── docs/
    ├── JENKINS-SETUP.md                    # Installation guide
    ├── CREDENTIALS-GUIDE.md                # Credential management
    ├── PIPELINE-USAGE.md                   # How to use pipelines
    └── TROUBLESHOOTING.md                  # Problem resolution
```

---

## Quick Start

### 1. Install Jenkins

```bash
# See docs/JENKINS-SETUP.md for complete instructions
sudo apt update
sudo apt install -y openjdk-17-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
```

### 2. Configure Credentials

```bash
# See docs/CREDENTIALS-GUIDE.md for detailed instructions
# Add these credentials in Jenkins:
- github-pat-btd (GitHub Personal Access Token)
- proxmox-api-token (Proxmox API token)
- ansible-ssh-private-key (SSH key for containers)
- consul-acl-token (Consul token for Terraform state)
- slack-webhook-url (Slack notifications)
```

### 3. Create Jobs

```bash
# Create seed job to generate all pipeline jobs
# Navigate to Jenkins > New Item > Freestyle Project
# Name: seed-job
# Build Steps > Process Job DSLs
# DSL Scripts: /root/projects/btd-app/jenkins/jobs/*.groovy
# Save and run
```

### 4. Run First Deployment

```bash
# Navigate to: btd-platform/main-deployment
# Build with Parameters:
#   - ENVIRONMENT: development
#   - SERVICES_TO_DEPLOY: all
# Click "Build"
```

---

## Pipelines

### Main Deployment Pipeline

**Job:** `btd-platform/main-deployment`
**Purpose:** Complete end-to-end deployment
**Stages:**
1. Checkout code
2. Build all 18 services (parallel)
3. Run tests (unit, integration, lint)
4. Provision infrastructure (Terraform)
5. Deploy applications (Ansible)
6. Run health checks and smoke tests
7. Notify team

**Usage:**
```bash
# Automatic trigger: Push to main/staging/development branch
# Manual trigger: Build with Parameters
```

### Infrastructure Pipeline

**Job:** `btd-platform/infrastructure-deployment`
**Purpose:** Terraform-only deployments
**Use Cases:**
- Infrastructure scaling
- Network changes
- Resource modifications

### Application Pipeline

**Job:** `btd-platform/application-deployment`
**Purpose:** Ansible-only deployments
**Use Cases:**
- Code updates
- Configuration changes
- Service restarts

### Build Verification Pipeline

**Job:** `btd-platform/build-verification`
**Purpose:** PR validation
**Trigger:** Automatic on PR open/update
**Stages:**
1. Build all services
2. Run tests
3. Check code quality
4. Update GitHub PR status

---

## Key Features

### ✅ Multi-Environment Support

```yaml
Environments:
  - development: Auto-deploy on push
  - staging: Auto-deploy with full tests
  - production: Manual approval required
```

### ✅ Parallel Execution

All 18 services build in parallel, reducing deployment time from ~30 minutes to ~8 minutes.

### ✅ Approval Gates

Production deployments require manual approval at:
- Terraform infrastructure changes
- Application deployment

### ✅ Automatic Rollback

On failure, pipelines automatically:
1. Stop failed services
2. Restore previous code version
3. Redeploy services
4. Verify rollback success
5. Alert team

### ✅ Health Monitoring

Comprehensive health checks:
- Infrastructure services (PostgreSQL, Redis, MinIO, Consul)
- All 18 microservices
- gRPC connectivity
- HTTP endpoints
- Service logs analysis

### ✅ Notification Integration

Slack notifications for:
- Deployment success/failure
- Approval requests
- Health check results
- Rollback triggers

---

## Environment Configuration

### Development

```yaml
Environment: development
Auto-deploy: true
Approval required: false
Notification: Email
Containers: 10.27.27.200-217
```

### Staging

```yaml
Environment: staging
Auto-deploy: true
Approval required: false
Notification: Slack
Containers: 10.27.27.150-167
```

### Production

```yaml
Environment: production
Auto-deploy: false
Approval required: true
Notification: Slack + Email
Containers: 10.27.27.100-117
```

---

## Scripts

### pre-deployment-checks.sh

Validates prerequisites before deployment:
- Infrastructure connectivity (Proxmox, Consul, PostgreSQL, Redis, MinIO)
- Terraform state accessibility
- Ansible inventory validity
- SSH key availability
- Port conflict detection
- Disk space availability

**Usage:**
```bash
./scripts/pre-deployment-checks.sh production
```

### post-deployment-health-check.sh

Verifies deployment success:
- All services responding
- Health endpoints returning 200
- gRPC ports accessible
- Database connectivity
- Redis connectivity
- No errors in logs

**Usage:**
```bash
./scripts/post-deployment-health-check.sh production
```

### rollback-deployment.sh

Automated rollback procedure:
- Stop failed services
- Restore previous code
- Rebuild services
- Redeploy with Ansible
- Verify rollback

**Usage:**
```bash
./scripts/rollback-deployment.sh <deployment_id> production
```

### smoke-tests.sh

Basic functionality tests:
- Infrastructure services
- API health checks
- Authentication endpoints
- Service discovery
- gRPC connectivity
- Database operations
- Cache operations
- Critical user flows

**Usage:**
```bash
./scripts/smoke-tests.sh production
```

### generate-ansible-inventory.py

Converts Terraform outputs to Ansible inventory:
- Reads Terraform JSON outputs
- Generates hosts.yml for Ansible
- Categorizes hosts by type
- Includes connection details

**Usage:**
```bash
python3 scripts/generate-ansible-inventory.py \
  terraform-outputs.json \
  ../btd-ansible/inventories/production/hosts.yml
```

---

## Integration Points

### GitHub

- **Webhooks:** Automatic builds on push/PR
- **Status checks:** PR build verification
- **Branch protection:** Require passing checks

### Terraform

- **State backend:** Consul at 10.27.27.27:8500
- **Provider:** Proxmox via API
- **Resources:** 24 LXC containers

### Ansible

- **Inventory:** Generated from Terraform outputs
- **Playbooks:** Located in ../btd-ansible/
- **Connection:** SSH via ansible_rsa key

### Proxmox

- **API:** https://10.27.27.192:8006/api2/json
- **Authentication:** API token
- **Resources:** LXC containers, networks, storage

### Consul

- **Address:** 10.27.27.27:8500
- **Purpose:** Terraform state, service discovery
- **Health checks:** Service registration

---

## Monitoring

### Jenkins Console

```
Navigate to build > Console Output
Watch for stage completion and errors
```

### Blue Ocean View

```
Navigate to build > Open Blue Ocean
Visual pipeline with parallel stage execution
```

### Slack Notifications

```
Channel: #btd-deployments
Notifications: Success, Failure, Approvals
```

### Health Dashboard

```bash
# Manual health check
./scripts/post-deployment-health-check.sh production
```

---

## Security

### Credentials

All sensitive data stored in Jenkins Credential Store:
- Encrypted at rest
- Masked in console output
- Audit logging enabled
- Regular rotation schedule

### SSH Keys

```bash
# Generated for Ansible
/var/lib/jenkins/.ssh/ansible_rsa

# Permissions
chmod 600 ansible_rsa
chown jenkins:jenkins ansible_rsa
```

### Network Security

- Jenkins accessible only from 10.27.27.0/23
- SSH key authentication only
- No password authentication
- Firewall rules enforced

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Pipeline stuck | Check executors, cancel hung builds |
| Build fails | Review console output, check dependencies |
| Terraform locked | Force unlock with `terraform force-unlock` |
| Ansible fails | Check SSH connectivity, verify inventory |
| Service unhealthy | Check logs, restart service, verify dependencies |

**See:** `docs/TROUBLESHOOTING.md` for comprehensive guide

---

## Documentation

### Complete Guides

1. **[JENKINS-SETUP.md](docs/JENKINS-SETUP.md)**
   - Installation instructions
   - Plugin configuration
   - System setup
   - Initial configuration

2. **[CREDENTIALS-GUIDE.md](docs/CREDENTIALS-GUIDE.md)**
   - Required credentials
   - Generation steps
   - Security best practices
   - Rotation schedule

3. **[PIPELINE-USAGE.md](docs/PIPELINE-USAGE.md)**
   - Pipeline descriptions
   - Usage examples
   - Common scenarios
   - Monitoring

4. **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**
   - Common issues
   - Diagnostic steps
   - Solutions
   - Emergency procedures

---

## Development Workflow

```
┌─────────────┐
│ Feature Dev │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Create PR  │ ──► Build Verification Pipeline
└──────┬──────┘
       │ (Tests pass)
       ▼
┌─────────────┐
│Merge to Dev │ ──► Auto-deploy to Development
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Merge to Stg │ ──► Auto-deploy to Staging
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Merge to Main│ ──► Manual deploy to Production
└─────────────┘     (with approval gates)
```

---

## Deployment Best Practices

1. **Always test in staging first**
2. **Use rolling deployments for production**
3. **Monitor health after deployment**
4. **Tag releases in Git**
5. **Document changes in CHANGELOG**
6. **Deploy during business hours (Tue-Thu)**
7. **Have rollback plan ready**
8. **Notify team before production deploy**

---

## Maintenance

### Weekly Tasks

- Review failed builds
- Check disk space usage
- Update outdated credentials
- Clean old build artifacts

### Monthly Tasks

- Update Jenkins and plugins
- Review and optimize pipelines
- Audit credential access
- Update documentation

### Quarterly Tasks

- Rotate credentials
- Review security settings
- Performance optimization
- Disaster recovery testing

---

## Support

### Internal Support

- **Slack:** #btd-devops
- **Email:** devops@btd-platform.com
- **Wiki:** Internal documentation

### External Resources

- **Jenkins Docs:** https://www.jenkins.io/doc/
- **Terraform Docs:** https://www.terraform.io/docs
- **Ansible Docs:** https://docs.ansible.com/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-10 | Initial release with complete CI/CD infrastructure |

---

## Contributing

To improve the Jenkins infrastructure:

1. Create feature branch
2. Update relevant Jenkinsfile/scripts
3. Test in development environment
4. Submit PR with detailed description
5. Update documentation

---

## License

Proprietary - BTD Platform
Internal use only

---

**Last Updated:** 2025-10-10
**Maintained by:** BTD DevOps Team
**Contact:** devops@btd-platform.com
