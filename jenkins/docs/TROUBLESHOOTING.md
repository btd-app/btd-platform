# BTD Platform - Jenkins Troubleshooting Guide

Comprehensive troubleshooting guide for Jenkins CI/CD pipelines.

**Network:** 10.27.27.0/23
**Jenkins Server:** 10.27.27.251
**Support:** devops@btd-platform.com

---

## Table of Contents

1. [Common Issues](#common-issues)
2. [Build Failures](#build-failures)
3. [Infrastructure Issues](#infrastructure-issues)
4. [Deployment Failures](#deployment-failures)
5. [Network Connectivity](#network-connectivity)
6. [Credential Problems](#credential-problems)
7. [Performance Issues](#performance-issues)
8. [Emergency Procedures](#emergency-procedures)

---

## Common Issues

### Issue: Jenkins is Not Responding

**Symptoms:**
- Cannot access http://10.27.27.251:8080
- Connection timeout
- 502 Bad Gateway

**Diagnosis:**

```bash
# Check if Jenkins is running
sudo systemctl status jenkins

# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check port availability
sudo netstat -tulpn | grep 8080

# Check Java process
ps aux | grep jenkins
```

**Solutions:**

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# If restart fails, check Java heap size
sudo vim /etc/default/jenkins
# Set: JAVA_ARGS="-Xmx2048m -Xms1024m"

# Clear Jenkins cache
sudo systemctl stop jenkins
sudo rm -rf /var/lib/jenkins/war/*
sudo systemctl start jenkins

# Check disk space
df -h

# If out of disk space, clean old builds
sudo rm -rf /var/lib/jenkins/jobs/*/builds/[0-9]*
```

---

### Issue: Pipeline Stuck at "Pending"

**Symptoms:**
- Build shows "Pending" status
- No executor available
- Queue is full

**Diagnosis:**

```bash
# Check executors
Navigate to: Jenkins > Manage Jenkins > Manage Nodes

# Check build queue
Navigate to: Jenkins > Build Queue
```

**Solutions:**

```bash
# Increase number of executors
Manage Jenkins > Configure System > # of executors: 4

# Cancel stuck builds
Navigate to build > Kill build

# Restart Jenkins agent
sudo systemctl restart jenkins

# Clear workspace
rm -rf /var/lib/jenkins/workspace/*
```

---

## Build Failures

### Issue: TypeScript Build Errors

**Symptoms:**
- `tsc: command not found`
- TypeScript compilation errors
- Type errors in services

**Diagnosis:**

```bash
# Check TypeScript installation
cd /root/projects/btd-app/btd-auth-service
npx tsc --version

# Check for type errors locally
npm run typecheck

# Check package.json dependencies
cat package.json | jq '.devDependencies.typescript'
```

**Solutions:**

```bash
# Reinstall dependencies
npm ci --force

# Clear node_modules and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build

# Update TypeScript version
npm install --save-dev typescript@latest

# Check tsconfig.json is present
ls -la tsconfig.json

# If Prisma types are missing
npx prisma generate
```

---

### Issue: npm install Fails

**Symptoms:**
- `EACCES: permission denied`
- `ENOTFOUND` registry errors
- Dependency resolution failures

**Diagnosis:**

```bash
# Check npm configuration
npm config list

# Check network connectivity
curl -I https://registry.npmjs.org

# Check disk space
df -h

# Check npm cache
npm cache verify
```

**Solutions:**

```bash
# Clear npm cache
npm cache clean --force

# Use offline mode (if registry is down)
npm install --prefer-offline

# Fix permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Configure npm registry
npm config set registry https://registry.npmjs.org/

# If using Verdaccio registry
npm config set registry http://10.27.27.XX:4873/

# Increase timeout
npm config set timeout 60000
```

---

### Issue: Proto File Not Found

**Symptoms:**
- `Cannot find proto files`
- gRPC initialization fails
- Import errors for .proto files

**Diagnosis:**

```bash
# Check proto files exist
ls -la btd-proto/

# Check if proto files copied to dist
ls -la btd-auth-service/dist/src/proto/

# Check build script
cat package.json | jq '.scripts.build'
```

**Solutions:**

```bash
# Update build script to copy proto files
# In package.json:
"build": "tsc && cp -r src/proto dist/src/"

# Manually copy proto files
cd btd-auth-service
mkdir -p dist/src/proto
cp -r src/proto/* dist/src/proto/

# Rebuild service
npm run build

# Verify proto files in dist
find dist -name "*.proto"
```

---

## Infrastructure Issues

### Issue: Terraform State Locked

**Symptoms:**
- `Error acquiring state lock`
- Cannot run terraform plan/apply
- Lock ID shown in error

**Diagnosis:**

```bash
# Check Consul for lock
curl http://10.27.27.27:8500/v1/kv/terraform/btd-production/state-lock

# Check Terraform lock info
cd /root/projects/btd-app/terraform
terraform force-unlock LOCK_ID
```

**Solutions:**

```bash
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID

# If lock is stuck, manually remove from Consul
curl -X DELETE http://10.27.27.27:8500/v1/kv/terraform/btd-production/state-lock

# Verify lock is removed
terraform plan

# Prevent future locks: ensure only one Terraform run at a time
```

---

### Issue: Terraform Apply Fails

**Symptoms:**
- Container creation fails
- Network configuration errors
- Resource already exists

**Diagnosis:**

```bash
# Check Terraform logs
cd /root/projects/btd-app/terraform
terraform plan -detailed-exitcode

# Check Proxmox API
curl -k https://10.27.27.192:8006/api2/json/version

# Check existing resources
pvesh get /cluster/resources --type vm
```

**Solutions:**

```bash
# Import existing resource
terraform import proxmox_lxc.container VMID

# Refresh Terraform state
terraform refresh

# Manually fix resource in Proxmox
# Then run:
terraform plan
terraform apply

# If resource conflict, destroy and recreate
terraform destroy -target=proxmox_lxc.container
terraform apply
```

---

### Issue: Proxmox API Connection Failed

**Symptoms:**
- `Error connecting to Proxmox`
- SSL certificate errors
- Authentication failures

**Diagnosis:**

```bash
# Test Proxmox API
curl -k https://10.27.27.192:8006/api2/json/version

# Test with credentials
curl -k -H "Authorization: PVEAPIToken=TOKEN" \
  https://10.27.27.192:8006/api2/json/version

# Check network connectivity
ping 10.27.27.192
```

**Solutions:**

```bash
# Update Proxmox credentials in Jenkins
Manage Jenkins > Manage Credentials > proxmox-api-token

# Verify token format
# Should be: USER@REALM!TOKENID=UUID
# Example: root@pam!jenkins=xxxx-xxxx-xxxx

# Test token manually
export PROXMOX_TOKEN="root@pam!jenkins=YOUR_TOKEN"
curl -k -H "Authorization: PVEAPIToken=$PROXMOX_TOKEN" \
  https://10.27.27.192:8006/api2/json/cluster/status

# If SSL errors, update Terraform provider
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}
```

---

## Deployment Failures

### Issue: Ansible Connection Failed

**Symptoms:**
- `SSH connection refused`
- `Permission denied (publickey)`
- Ansible cannot reach hosts

**Diagnosis:**

```bash
# Test SSH connection
ssh -i /var/lib/jenkins/.ssh/ansible_rsa root@10.27.27.100

# Check Ansible inventory
cd /root/projects/btd-app/btd-ansible
ansible-inventory -i inventories/production/hosts.yml --list

# Test Ansible ping
ansible all -i inventories/production/hosts.yml \
  --private-key=/var/lib/jenkins/.ssh/ansible_rsa \
  -m ping
```

**Solutions:**

```bash
# Ensure SSH key has correct permissions
chmod 600 /var/lib/jenkins/.ssh/ansible_rsa
chown jenkins:jenkins /var/lib/jenkins/.ssh/ansible_rsa

# Deploy public key to all containers
ssh-copy-id -i /var/lib/jenkins/.ssh/ansible_rsa.pub root@10.27.27.100

# Verify authorized_keys on container
ssh root@10.27.27.100 "cat ~/.ssh/authorized_keys"

# Update Ansible inventory with correct IPs
vim inventories/production/hosts.yml

# Disable host key checking (if needed)
export ANSIBLE_HOST_KEY_CHECKING=False
```

---

### Issue: Service Won't Start After Deployment

**Symptoms:**
- Systemd service fails to start
- Service exits immediately
- Port already in use

**Diagnosis:**

```bash
# SSH to container
ssh root@10.27.27.100

# Check service status
systemctl status btd-auth-service

# Check service logs
journalctl -u btd-auth-service -f

# Check if port is in use
netstat -tulpn | grep 50051

# Check environment variables
systemctl show btd-auth-service --property=Environment
```

**Solutions:**

```bash
# Fix systemd service file
vim /etc/systemd/system/btd-auth-service.service

# Reload systemd
systemctl daemon-reload

# Restart service
systemctl restart btd-auth-service

# Check for errors
journalctl -u btd-auth-service -n 100 --no-pager

# If port conflict, kill process
lsof -ti:50051 | xargs kill -9

# Check file permissions
ls -la /opt/btd-app/btd-auth-service/
chown -R btd:btd /opt/btd-app/

# Check Node.js version
node --version
```

---

### Issue: Database Migration Fails

**Symptoms:**
- `Migration failed`
- Database connection errors
- Migration already applied

**Diagnosis:**

```bash
# Check database connectivity
PGPASSWORD='password' psql -h 10.27.27.30 -U btd_admin -d btd_platform -c "SELECT version();"

# Check migration status
cd /opt/btd-app/btd-auth-service
npx prisma migrate status

# Check migration history
psql -h 10.27.27.30 -U btd_admin -d btd_platform -c "SELECT * FROM _prisma_migrations;"
```

**Solutions:**

```bash
# Mark migration as applied
npx prisma migrate resolve --applied "20231010_migration_name"

# Roll back failed migration
npx prisma migrate resolve --rolled-back "20231010_migration_name"

# Reset database (DANGER - dev only!)
npx prisma migrate reset

# Force re-apply migrations
npx prisma migrate deploy --force

# Check for migration conflicts
npx prisma migrate diff \
  --from-schema-datamodel=prisma/schema.prisma \
  --to-schema-datasource=prisma/schema.prisma
```

---

## Network Connectivity

### Issue: Cannot Reach Infrastructure Services

**Symptoms:**
- PostgreSQL connection timeout
- Redis connection refused
- Consul not accessible

**Diagnosis:**

```bash
# Test connectivity from Jenkins
ping 10.27.27.30  # PostgreSQL
ping 10.27.27.26  # Redis
ping 10.27.27.27  # Consul
ping 10.27.27.28  # MinIO

# Test port connectivity
nc -zv 10.27.27.30 5432
nc -zv 10.27.27.26 6379
nc -zv 10.27.27.27 8500

# Check routing
ip route | grep 10.27.27.0

# Check firewall rules
sudo iptables -L -n
```

**Solutions:**

```bash
# Add route if missing
sudo ip route add 10.27.27.0/23 via 10.27.27.1

# Make route persistent
sudo vim /etc/netplan/01-network.yaml
# Add route configuration

# Check container is running (from Proxmox)
pct list
pct status 100

# Start container if stopped
pct start 100

# Check container network
pct exec 100 -- ip addr

# Restart networking
sudo systemctl restart networking
```

---

### Issue: GitHub Webhook Not Working

**Symptoms:**
- Push to GitHub doesn't trigger build
- No webhook deliveries shown
- 404 errors in webhook logs

**Diagnosis:**

```bash
# Check webhook configuration
Navigate to: GitHub > Repository > Settings > Webhooks

# Check Jenkins GitHub plugin
Manage Jenkins > Manage Plugins > Installed > GitHub plugin

# Check Jenkins logs
sudo journalctl -u jenkins | grep -i webhook

# Test webhook manually
curl -X POST http://10.27.27.251:8080/github-webhook/
```

**Solutions:**

```bash
# Update webhook URL
Webhook URL: http://10.27.27.251:8080/github-webhook/

# Enable GitHub hook trigger in job
Job Configuration > Build Triggers > GitHub hook trigger for GITScm polling

# Redeliver webhook from GitHub
Repository > Settings > Webhooks > Recent Deliveries > Redeliver

# Check firewall allows GitHub IPs
# GitHub webhook IPs: 192.30.252.0/22, 185.199.108.0/22

# Restart Jenkins
sudo systemctl restart jenkins

# Verify GitHub credentials
Manage Jenkins > Configure System > GitHub Server > Test connection
```

---

## Credential Problems

### Issue: Credential Not Found

**Symptoms:**
- `Credentials 'xxx' not found`
- Pipeline fails at credential step
- Invalid credential ID

**Diagnosis:**

```bash
# List all credentials via Jenkins CLI
java -jar jenkins-cli.jar -s http://10.27.27.251:8080/ \
  -auth admin:password \
  list-credentials system::system::jenkins

# Check credential ID in pipeline
# Must match exactly (case-sensitive)
```

**Solutions:**

```bash
# Verify credential exists
Manage Jenkins > Manage Credentials > (global) domain

# Check credential ID matches
# Pipeline: credentialsId: 'github-pat-btd'
# Jenkins: ID: github-pat-btd

# Re-create credential if missing
# Use exact ID from pipeline

# Check credential scope
# Must be 'Global' or accessible to job domain
```

---

### Issue: SSH Key Authentication Failed

**Symptoms:**
- `Permission denied (publickey)`
- Ansible cannot connect
- SSH connection refused

**Diagnosis:**

```bash
# Test SSH key manually
ssh -i /var/lib/jenkins/.ssh/ansible_rsa -v root@10.27.27.100

# Check key permissions
ls -la /var/lib/jenkins/.ssh/ansible_rsa

# Check authorized_keys on remote
ssh root@10.27.27.100 "cat ~/.ssh/authorized_keys"
```

**Solutions:**

```bash
# Fix key permissions
chmod 600 /var/lib/jenkins/.ssh/ansible_rsa
chmod 644 /var/lib/jenkins/.ssh/ansible_rsa.pub
chown jenkins:jenkins /var/lib/jenkins/.ssh/ansible_rsa*

# Redeploy public key
for i in {100..117}; do
  ssh-copy-id -i /var/lib/jenkins/.ssh/ansible_rsa.pub root@10.27.27.$i
done

# Update credential in Jenkins
Manage Jenkins > Manage Credentials > ansible-ssh-private-key
# Ensure private key matches /var/lib/jenkins/.ssh/ansible_rsa

# Test again
ansible all -i inventories/production/hosts.yml \
  --private-key=/var/lib/jenkins/.ssh/ansible_rsa \
  -m ping
```

---

## Performance Issues

### Issue: Pipeline Takes Too Long

**Symptoms:**
- Build exceeds timeout
- Stages run sequentially instead of parallel
- Slow network transfers

**Diagnosis:**

```bash
# Check pipeline duration
Navigate to build > Pipeline Steps

# Identify slow stages
# Look for stages taking > 5 minutes

# Check network bandwidth
iperf3 -s  # on target
iperf3 -c 10.27.27.100  # from Jenkins

# Check CPU usage
top
```

**Solutions:**

```bash
# Increase timeout in Jenkinsfile
options {
    timeout(time: 90, unit: 'MINUTES')
}

# Optimize parallel builds
# Ensure services build in parallel

# Use npm cache
npm ci --prefer-offline

# Enable build caching
# Don't rebuild if no changes

# Increase Jenkins executors
Manage Jenkins > Configure System > # of executors: 4

# Add build agents (if needed)
# Distribute builds across multiple nodes
```

---

### Issue: Out of Disk Space

**Symptoms:**
- `No space left on device`
- Build fails during npm install
- Cannot write files

**Diagnosis:**

```bash
# Check disk usage
df -h

# Check Jenkins workspace size
du -sh /var/lib/jenkins/workspace/*

# Check build artifacts
du -sh /var/lib/jenkins/jobs/*/builds/*
```

**Solutions:**

```bash
# Clean old builds
find /var/lib/jenkins/jobs/*/builds -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;

# Clean old workspaces
find /var/lib/jenkins/workspace -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Clean npm cache
npm cache clean --force

# Clean Docker (if used)
docker system prune -a

# Configure build discard
# In Jenkinsfile:
options {
    buildDiscarder(logRotator(numToKeepStr: '30'))
}

# Add more disk space
# Expand LVM volume or add disk
```

---

## Emergency Procedures

### Emergency Rollback

If a deployment breaks production:

```bash
# 1. Access Jenkins immediately
http://10.27.27.251:8080

# 2. Run rollback job
Job: btd-platform/rollback-deployment
Parameters:
  - ENVIRONMENT: production
  - DEPLOYMENT_ID: [leave empty for last]
  - SERVICES: all

# 3. Approve rollback

# 4. Monitor rollback progress

# 5. Verify services are healthy
./jenkins/scripts/post-deployment-health-check.sh production

# 6. Notify team in Slack
"Production rollback completed. Investigating root cause."
```

### Manual Service Restart

If services are unhealthy:

```bash
# 1. SSH to affected container
ssh root@10.27.27.101  # auth-service

# 2. Check service status
systemctl status btd-auth-service

# 3. Restart service
systemctl restart btd-auth-service

# 4. Check logs
journalctl -u btd-auth-service -f

# 5. Verify health
curl http://localhost:3005/health

# 6. If still failing, check dependencies
# - Database connection
# - Redis connection
# - Environment variables
```

### Jenkins Recovery

If Jenkins is completely broken:

```bash
# 1. Stop Jenkins
sudo systemctl stop jenkins

# 2. Backup current state
sudo tar -czf /tmp/jenkins-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/config.xml \
  /var/lib/jenkins/credentials.xml \
  /var/lib/jenkins/jobs/

# 3. Clear cache and workspace
sudo rm -rf /var/lib/jenkins/war/*
sudo rm -rf /var/lib/jenkins/workspace/*

# 4. Restart Jenkins
sudo systemctl start jenkins

# 5. If still failing, restore from backup
sudo systemctl stop jenkins
sudo tar -xzf /var/backups/jenkins/jenkins-latest.tar.gz -C /
sudo systemctl start jenkins
```

---

## Getting Help

### Contact Support

- **Slack:** #btd-devops
- **Email:** devops@btd-platform.com
- **On-call:** (Emergency only)

### Log Collection

When reporting issues, provide:

```bash
# Collect Jenkins logs
sudo journalctl -u jenkins --since "1 hour ago" > jenkins.log

# Collect build logs
# Navigate to build > Console Output > Download

# Collect service logs
ssh root@10.27.27.101 "journalctl -u btd-auth-service -n 1000" > service.log

# Collect system info
uname -a > sysinfo.txt
df -h >> sysinfo.txt
free -h >> sysinfo.txt

# Package and send
tar -czf issue-$(date +%Y%m%d-%H%M%S).tar.gz *.log sysinfo.txt
```

---

**Last Updated:** 2025-10-10
**Version:** 1.0
**Maintained by:** BTD DevOps Team
