# Jenkins Setup Guide for BTD Platform

Complete guide for installing and configuring Jenkins for BTD platform CI/CD.

**Network:** 10.27.27.0/23
**Jenkins Server:** 10.27.27.251
**Environment:** Production-ready deployment automation

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Jenkins Installation](#jenkins-installation)
3. [Initial Configuration](#initial-configuration)
4. [Plugin Installation](#plugin-installation)
5. [System Configuration](#system-configuration)
6. [Job Configuration](#job-configuration)
7. [Security Setup](#security-setup)
8. [Verification](#verification)

---

## Prerequisites

### System Requirements

- **OS:** Ubuntu 22.04 LTS or later
- **Memory:** Minimum 4GB RAM (8GB recommended)
- **Disk:** 50GB available space
- **Network:** Access to 10.27.27.0/23 subnet
- **Java:** OpenJDK 17 or later

### Network Access Requirements

Jenkins server must have access to:
- **Proxmox API:** 10.27.27.192:8006
- **Consul:** 10.27.27.27:8500
- **PostgreSQL:** 10.27.27.30:5432
- **Redis:** 10.27.27.26:6379
- **MinIO:** 10.27.27.28:9000
- **GitHub:** api.github.com (HTTPS)
- **All LXC containers:** 10.27.27.100-10.27.27.117

---

## Jenkins Installation

### Step 1: Install Java

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install OpenJDK 17
sudo apt install -y openjdk-17-jdk

# Verify installation
java -version
```

### Step 2: Install Jenkins

```bash
# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
```

### Step 3: Configure Firewall

```bash
# Allow Jenkins port
sudo ufw allow 8080/tcp

# Allow SSH (if needed)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable
```

### Step 4: Initial Setup

```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins at http://10.27.27.251:8080
# Enter the initial admin password
```

---

## Initial Configuration

### 1. Install Suggested Plugins

When prompted, select **"Install suggested plugins"** which includes:
- Git plugin
- Pipeline plugin
- Credentials plugin
- SSH Agent plugin
- Mailer plugin

### 2. Create Admin User

Create the first admin user with:
- **Username:** admin
- **Password:** (strong password)
- **Full name:** BTD Platform Admin
- **Email:** devops@btd-platform.com

### 3. Configure Jenkins URL

Set Jenkins URL to: `http://10.27.27.251:8080/`

---

## Plugin Installation

### Required Plugins

Install these additional plugins for BTD platform:

```
Manage Jenkins > Manage Plugins > Available
```

#### Essential Plugins:

1. **Pipeline Plugins**
   - Pipeline
   - Pipeline: Stage View
   - Pipeline: GitHub Groovy Libraries
   - Pipeline Utility Steps
   - Pipeline: Build Step

2. **Git Plugins**
   - Git plugin
   - GitHub plugin
   - GitHub Branch Source plugin
   - GitHub Pull Request Builder

3. **Ansible Plugin**
   - Ansible plugin

4. **Notification Plugins**
   - Slack Notification plugin
   - Email Extension plugin
   - HTTP Request plugin

5. **Utility Plugins**
   - Credentials Binding plugin
   - SSH Agent plugin
   - Timestamper
   - AnsiColor
   - Blue Ocean (optional, for better UI)

6. **Job DSL Plugin**
   - Job DSL plugin

### Installation Command (via Jenkins CLI)

```bash
# Download Jenkins CLI
wget http://10.27.27.251:8080/jnlpJars/jenkins-cli.jar

# Install plugins
java -jar jenkins-cli.jar -s http://10.27.27.251:8080/ \
  -auth admin:YOUR_PASSWORD \
  install-plugin \
  pipeline-stage-view \
  github \
  github-branch-source \
  ansible \
  slack \
  credentials-binding \
  ssh-agent \
  timestamper \
  ansicolor \
  job-dsl

# Restart Jenkins
java -jar jenkins-cli.jar -s http://10.27.27.251:8080/ \
  -auth admin:YOUR_PASSWORD safe-restart
```

---

## System Configuration

### 1. Configure Global Tools

Navigate to: `Manage Jenkins > Global Tool Configuration`

#### Git Configuration

- **Name:** Default
- **Path to Git executable:** `/usr/bin/git`

#### Ansible Configuration

```bash
# Install Ansible on Jenkins server
sudo apt install -y ansible

# Verify installation
ansible --version
```

In Jenkins:
- **Name:** Ansible 2.x
- **Path to ansible executables directory:** `/usr/bin/`

### 2. Configure System Settings

Navigate to: `Manage Jenkins > Configure System`

#### GitHub Configuration

Add GitHub Server:
- **API URL:** `https://api.github.com`
- **Credentials:** Select `github-pat-btd` (create first - see Credentials Guide)
- **Manage hooks:** ☑ Enabled

#### Email Configuration

Configure email notifications:
- **SMTP server:** your-smtp-server.com
- **SMTP port:** 587
- **Use SMTP Authentication:** ☑
- **Username:** notifications@btd-platform.com
- **Password:** (from credentials)
- **Use SSL:** ☑
- **Reply-To Address:** noreply@btd-platform.com

#### Slack Configuration (Optional)

- **Workspace:** BTD Platform
- **Credential:** Select Slack webhook credential
- **Default channel:** #btd-deployments

### 3. Configure Environment Variables

Add global environment variables:

```
PROXMOX_API_URL = https://10.27.27.192:8006/api2/json
CONSUL_HTTP_ADDR = 10.27.27.27:8500
TERRAFORM_STATE_BACKEND = consul
BTD_APP_ROOT = /root/projects/btd-app
ANSIBLE_HOST_KEY_CHECKING = False
```

---

## Job Configuration

### 1. Create Jenkins Directory Structure

```bash
sudo mkdir -p /var/lib/jenkins/jobs
sudo mkdir -p /var/lib/jenkins/workspace
sudo mkdir -p /var/lib/jenkins/terraform-backups
sudo mkdir -p /var/lib/jenkins/rollback-states
sudo chown -R jenkins:jenkins /var/lib/jenkins
```

### 2. Set Up SSH Keys for Ansible

```bash
# Generate SSH key for Ansible
sudo -u jenkins ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/ansible_rsa -N ""

# Display public key
cat /var/lib/jenkins/.ssh/ansible_rsa.pub

# Copy this public key to all LXC containers:
# ssh-copy-id -i /var/lib/jenkins/.ssh/ansible_rsa.pub root@10.27.27.100
# (Repeat for all containers 10.27.27.100-117)
```

### 3. Clone BTD Repository

```bash
# Clone BTD application to Jenkins server
cd /root/projects
git clone https://github.com/btd-app/btd-app.git

# Verify Jenkins directory structure
ls /root/projects/btd-app/jenkins/
```

### 4. Create Jobs Using Job DSL

Navigate to: `New Item > Freestyle project`

- **Name:** seed-job
- **Build Steps:**
  - Add build step: "Process Job DSLs"
  - Select: "Look on Filesystem"
  - **DSL Scripts:** `/root/projects/btd-app/jenkins/jobs/*.groovy`

Run the seed job to create all pipeline jobs automatically.

---

## Security Setup

### 1. Enable Security Realm

Navigate to: `Manage Jenkins > Configure Global Security`

#### Authentication

- **Security Realm:** Jenkins' own user database
- **Allow users to sign up:** ☐ Disabled (for production)

#### Authorization

- **Authorization:** Matrix-based security

Configure permissions:
- **admin:** All permissions
- **devops-team:** Build, Read, Workspace
- **developers:** Read only

### 2. Configure Credentials

See `CREDENTIALS-GUIDE.md` for detailed instructions.

### 3. Enable CSRF Protection

- **Prevent Cross Site Request Forgery exploits:** ☑ Enabled

### 4. Configure Agent Security

- **TCP port for inbound agents:** Fixed (50000)
- **Enable agent → master access control:** ☑ Enabled

### 5. Configure Build Security

- **Markup Formatter:** Safe HTML
- **Prevent builds from starting until Jenkins is fully initialized:** ☑ Enabled

---

## Verification

### 1. Test Jenkins Installation

```bash
# Check Jenkins is running
sudo systemctl status jenkins

# Check Jenkins is accessible
curl -I http://10.27.27.251:8080/
```

### 2. Test Plugin Installation

Navigate to: `Manage Jenkins > Manage Plugins > Installed`

Verify all required plugins are installed and active.

### 3. Test Connectivity

Create a test pipeline:

```groovy
pipeline {
    agent any
    stages {
        stage('Test Connectivity') {
            steps {
                script {
                    // Test Proxmox
                    sh 'curl -k -s https://10.27.27.192:8006/api2/json/version'

                    // Test Consul
                    sh 'curl -s http://10.27.27.27:8500/v1/status/leader'

                    // Test GitHub
                    sh 'git ls-remote https://github.com/btd-app/btd-app.git HEAD'
                }
            }
        }
    }
}
```

Run this pipeline to verify network connectivity.

### 4. Test Ansible Connection

```bash
# Test Ansible from Jenkins server
cd /root/projects/btd-app/btd-ansible
ansible all -i inventories/development/hosts.yml -m ping
```

### 5. Run Build Verification Pipeline

Trigger the build verification pipeline manually:

```
btd-platform/build-verification
```

Expected result: All services build successfully.

---

## Post-Installation Tasks

### 1. Configure Backups

Set up Jenkins configuration backup:

```bash
# Install ThinBackup plugin
# Or use script
sudo mkdir -p /var/backups/jenkins
sudo cat > /etc/cron.daily/jenkins-backup << 'EOF'
#!/bin/bash
tar -czf /var/backups/jenkins/jenkins-config-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/config.xml \
  /var/lib/jenkins/credentials.xml \
  /var/lib/jenkins/jobs/*/config.xml
find /var/backups/jenkins -name "*.tar.gz" -mtime +30 -delete
EOF
sudo chmod +x /etc/cron.daily/jenkins-backup
```

### 2. Configure Monitoring

Set up monitoring for Jenkins:

```bash
# Install monitoring plugin or external monitoring
# Example: Prometheus + Grafana
```

### 3. Configure Log Rotation

```bash
# Configure Jenkins log rotation
sudo cat > /etc/logrotate.d/jenkins << 'EOF'
/var/log/jenkins/jenkins.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 jenkins jenkins
}
EOF
```

---

## Troubleshooting

### Jenkins Won't Start

```bash
# Check Java version
java -version

# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check port conflicts
sudo netstat -tulpn | grep 8080

# Reset Jenkins
sudo systemctl restart jenkins
```

### Plugin Installation Fails

```bash
# Check internet connectivity
curl -I https://updates.jenkins.io/

# Clear plugin cache
sudo rm -rf /var/lib/jenkins/plugins/*.jpi.tmp

# Restart Jenkins
sudo systemctl restart jenkins
```

### Permission Denied Errors

```bash
# Fix Jenkins permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod -R 755 /var/lib/jenkins
```

---

## Next Steps

1. ✅ Complete credential configuration (see `CREDENTIALS-GUIDE.md`)
2. ✅ Set up GitHub webhooks (see `webhook-config.json`)
3. ✅ Review pipeline usage (see `PIPELINE-USAGE.md`)
4. ✅ Configure monitoring and alerts
5. ✅ Run first deployment

---

## Resources

- **Jenkins Documentation:** https://www.jenkins.io/doc/
- **Pipeline Syntax:** https://www.jenkins.io/doc/book/pipeline/syntax/
- **Plugin Index:** https://plugins.jenkins.io/
- **BTD Platform Wiki:** (internal documentation)

---

**Last Updated:** 2025-10-10
**Version:** 1.0
**Maintained by:** BTD DevOps Team
