# BTD Platform - Jenkins Quick Reference

Fast reference for common Jenkins operations.

**Jenkins:** http://10.27.27.251:8080
**Network:** 10.27.27.0/23

---

## Quick Commands

### Deploy to Development

```bash
# Navigate to Jenkins
http://10.27.27.251:8080/job/btd-platform/job/main-deployment/

# Build with Parameters:
ENVIRONMENT: development
SERVICES_TO_DEPLOY: all
```

### Deploy to Production

```bash
# Navigate to Jenkins
http://10.27.27.251:8080/job/btd-platform/job/main-deployment/

# Build with Parameters:
ENVIRONMENT: production
SERVICES_TO_DEPLOY: all

# Approve Terraform changes when prompted
# Approve Application deployment when prompted
```

### Deploy Single Service

```bash
# Navigate to Jenkins
http://10.27.27.251:8080/job/btd-platform/job/application-deployment/

# Build with Parameters:
ENVIRONMENT: production
SERVICES: btd-auth-service
ROLLING_DEPLOYMENT: true
```

### Rollback Deployment

```bash
# Navigate to Jenkins
http://10.27.27.251:8080/job/btd-platform/job/rollback-deployment/

# Build with Parameters:
ENVIRONMENT: production
DEPLOYMENT_ID: [leave empty for last]
SERVICES: all

# Approve when prompted
```

---

## Health Checks

### Run Health Check

```bash
ssh root@10.27.27.251
cd /root/projects/btd-app/jenkins/scripts
./post-deployment-health-check.sh production
```

### Run Smoke Tests

```bash
./smoke-tests.sh production
```

### Check Service Status

```bash
# SSH to container
ssh root@10.27.27.101  # auth-service

# Check service
systemctl status btd-auth-service

# View logs
journalctl -u btd-auth-service -f
```

---

## Troubleshooting

### Pipeline Stuck

```bash
# Cancel build
Navigate to build > Kill build

# Restart Jenkins
ssh root@10.27.27.251
sudo systemctl restart jenkins
```

### Build Fails

```bash
# 1. Check console output
Navigate to build > Console Output

# 2. Review error message
# 3. Check specific service logs
# 4. Test build locally
cd /root/projects/btd-app/btd-auth-service
npm run build
```

### Terraform Locked

```bash
ssh root@10.27.27.251
cd /root/projects/btd-app/terraform
terraform force-unlock LOCK_ID
```

### Ansible Connection Failed

```bash
# Test SSH
ssh -i /var/lib/jenkins/.ssh/ansible_rsa root@10.27.27.100

# Test Ansible
cd /root/projects/btd-app/btd-ansible
ansible all -i inventories/production/hosts.yml \
  --private-key=/var/lib/jenkins/.ssh/ansible_rsa \
  -m ping
```

### Service Won't Start

```bash
# SSH to container
ssh root@10.27.27.101

# Check status
systemctl status btd-auth-service

# Restart
systemctl restart btd-auth-service

# Check logs
journalctl -u btd-auth-service -n 100
```

---

## Common URLs

| Service | URL |
|---------|-----|
| Jenkins | http://10.27.27.251:8080 |
| Orchestrator Health | http://10.27.27.100:9130/api/v1/health |
| Consul | http://10.27.27.27:8500 |
| MinIO | http://10.27.27.28:9000 |
| Proxmox | https://10.27.27.192:8006 |

---

## Pipeline Jobs

| Job | Path |
|-----|------|
| Main Deployment | btd-platform/main-deployment |
| Infrastructure | btd-platform/infrastructure-deployment |
| Application | btd-platform/application-deployment |
| Build Verification | btd-platform/build-verification |
| Hotfix | btd-platform/hotfix-deployment |
| Rollback | btd-platform/rollback-deployment |

---

## File Locations

| Item | Path |
|------|------|
| Jenkinsfiles | /root/projects/btd-app/jenkins/ |
| Scripts | /root/projects/btd-app/jenkins/scripts/ |
| Docs | /root/projects/btd-app/jenkins/docs/ |
| Terraform | /root/projects/btd-app/terraform/ |
| Ansible | /root/projects/btd-app/btd-ansible/ |
| SSH Key | /var/lib/jenkins/.ssh/ansible_rsa |

---

## Credentials

Required credentials in Jenkins:
- `github-pat-btd`
- `proxmox-api-token`
- `ansible-ssh-private-key`
- `consul-acl-token`
- `slack-webhook-url`

**Add via:** Manage Jenkins > Manage Credentials

---

## Container IPs

### Infrastructure
- PostgreSQL: 10.27.27.30
- Redis: 10.27.27.26
- MinIO: 10.27.27.28
- Consul: 10.27.27.27

### Services (Production)
- Orchestrator: 10.27.27.100
- Auth: 10.27.27.101
- Users: 10.27.27.102
- Matches: 10.27.27.103
- Messaging: 10.27.27.104
- (etc.)

---

## Emergency Contacts

- **Slack:** #btd-devops
- **Email:** devops@btd-platform.com
- **On-call:** (Emergency only)

---

## Quick Diagnostics

### Check All Services

```bash
curl http://10.27.27.100:9130/api/v1/health
curl http://10.27.27.27:8500/v1/status/leader
curl http://10.27.27.28:9000/minio/health/live
nc -zv 10.27.27.30 5432  # PostgreSQL
nc -zv 10.27.27.26 6379  # Redis
```

### Check Disk Space

```bash
ssh root@10.27.27.251
df -h
```

### Check Jenkins Logs

```bash
sudo journalctl -u jenkins -f
```

### Check Build Queue

```
Navigate to: http://10.27.27.251:8080/queue/
```

---

**For detailed information, see:**
- JENKINS-SETUP.md
- PIPELINE-USAGE.md
- TROUBLESHOOTING.md
