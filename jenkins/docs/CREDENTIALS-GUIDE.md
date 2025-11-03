## CREDENTIALS-GUIDE.md

Complete guide for managing credentials in Jenkins for BTD platform deployment.

**Security Level:** CRITICAL
**Network:** 10.27.27.0/23
**Jenkins Server:** 10.27.27.251

---

## Table of Contents

1. [Overview](#overview)
2. [Required Credentials](#required-credentials)
3. [Adding Credentials](#adding-credentials)
4. [Credential Types](#credential-types)
5. [Security Best Practices](#security-best-practices)
6. [Credential Rotation](#credential-rotation)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Jenkins uses a secure credential store to manage sensitive information. All credentials are encrypted at rest and masked in console output.

### Credential Domains

- **Global:** Available to all jobs
- **System:** Only for Jenkins system operations
- **Project-specific:** Scoped to specific jobs (recommended for production)

---

## Required Credentials

### 1. GitHub Personal Access Token

**ID:** `github-pat-btd`
**Type:** Secret text
**Purpose:** Access to btd-app GitHub repositories

#### Generation Steps:

1. Log in to GitHub
2. Navigate to: Settings > Developer settings > Personal access tokens > Tokens (classic)
3. Click "Generate new token (classic)"
4. Configure token:
   - **Note:** Jenkins BTD Platform
   - **Expiration:** 90 days
   - **Scopes:**
     - ☑ repo (all)
     - ☑ workflow
     - ☑ admin:repo_hook
5. Click "Generate token"
6. Copy token immediately (shown only once)

#### Adding to Jenkins:

```
Manage Jenkins > Manage Credentials > (global) > Add Credentials

Kind: Secret text
Scope: Global
Secret: [paste token]
ID: github-pat-btd
Description: GitHub Personal Access Token for btd-app repository
```

#### Verification:

```bash
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

---

### 2. Proxmox API Token

**ID:** `proxmox-api-token`
**Type:** Secret text
**Purpose:** Terraform infrastructure provisioning on Proxmox

#### Generation Steps:

1. Log in to Proxmox web UI: https://10.27.27.192:8006
2. Navigate to: Datacenter > Permissions > API Tokens
3. Click "Add"
4. Configure token:
   - **User:** root@pam
   - **Token ID:** jenkins
   - **Privilege Separation:** ☐ Disabled (for full permissions)
5. Click "Add"
6. Copy token (shown only once)

#### Token Format:

```
root@pam!jenkins=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### Required Permissions:

```
Datacenter:
  - VM.Allocate
  - VM.Config.Network
  - VM.Config.Disk
  - Datastore.AllocateSpace
  - Sys.Modify
```

#### Adding to Jenkins:

```
Kind: Secret text
Scope: Global
Secret: root@pam!jenkins=TOKEN_UUID
ID: proxmox-api-token
Description: Proxmox API token for infrastructure provisioning
```

#### Verification:

```bash
export PROXMOX_TOKEN="root@pam!jenkins=YOUR_TOKEN"
curl -k -H "Authorization: PVEAPIToken=$PROXMOX_TOKEN" \
  https://10.27.27.192:8006/api2/json/version
```

---

### 3. Ansible SSH Private Key

**ID:** `ansible-ssh-private-key`
**Type:** SSH Username with private key
**Purpose:** Ansible access to LXC containers

#### Generation Steps:

```bash
# Generate SSH key pair
sudo -u jenkins ssh-keygen -t rsa -b 4096 \
  -f /var/lib/jenkins/.ssh/ansible_rsa \
  -N "" \
  -C "jenkins@btd-platform"

# Set correct permissions
sudo chmod 600 /var/lib/jenkins/.ssh/ansible_rsa
sudo chmod 644 /var/lib/jenkins/.ssh/ansible_rsa.pub
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/ansible_rsa*

# Display public key
cat /var/lib/jenkins/.ssh/ansible_rsa.pub
```

#### Deploy Public Key to Containers:

```bash
# Create deployment script
cat > /tmp/deploy-ssh-key.sh << 'EOF'
#!/bin/bash
PUBLIC_KEY="ssh-rsa AAAAB3... jenkins@btd-platform"

for ip in {100..117}; do
    echo "Deploying to 10.27.27.$ip..."
    ssh root@10.27.27.$ip "
        mkdir -p ~/.ssh
        echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/authorized_keys
    " || echo "Failed: 10.27.27.$ip"
done
EOF

chmod +x /tmp/deploy-ssh-key.sh
/tmp/deploy-ssh-key.sh
```

#### Adding to Jenkins:

```
Kind: SSH Username with private key
Scope: Global
ID: ansible-ssh-private-key
Description: Ansible SSH key for LXC container access
Username: root
Private Key: Enter directly
  [paste contents of /var/lib/jenkins/.ssh/ansible_rsa]
Passphrase: [leave empty if no passphrase]
```

#### Verification:

```bash
# Test SSH connection
ssh -i /var/lib/jenkins/.ssh/ansible_rsa root@10.27.27.100 hostname

# Test Ansible
cd /root/projects/btd-app/btd-ansible
ansible all -i inventories/development/hosts.yml \
  --private-key=/var/lib/jenkins/.ssh/ansible_rsa \
  -m ping
```

---

### 4. Consul ACL Token

**ID:** `consul-acl-token`
**Type:** Secret text
**Purpose:** Terraform state backend in Consul

#### Generation Steps (if ACLs enabled):

```bash
# Connect to Consul server
ssh root@10.27.27.27

# Create token
consul acl token create \
  -description "Jenkins Terraform State Backend" \
  -policy-name "terraform-state-policy"

# Copy the SecretID
```

#### Required Policy:

```hcl
# terraform-state-policy.hcl
key_prefix "terraform/" {
  policy = "write"
}

session_prefix "" {
  policy = "write"
}
```

#### Adding to Jenkins:

```
Kind: Secret text
Scope: Global
Secret: [paste Consul ACL token SecretID]
ID: consul-acl-token
Description: Consul ACL token for Terraform state backend
```

#### Verification:

```bash
export CONSUL_HTTP_TOKEN="YOUR_TOKEN"
curl -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
  http://10.27.27.27:8500/v1/kv/terraform/
```

---

### 5. Slack Webhook URL

**ID:** `slack-webhook-url`
**Type:** Secret text
**Purpose:** Deployment notifications
**Optional:** Yes

#### Generation Steps:

1. Log in to Slack workspace
2. Navigate to: Apps > Incoming Webhooks
3. Click "Add to Slack"
4. Select channel: #btd-deployments
5. Click "Add Incoming WebHooks integration"
6. Copy Webhook URL

#### Webhook Format:

```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

#### Adding to Jenkins:

```
Kind: Secret text
Scope: Global
Secret: [paste Slack webhook URL]
ID: slack-webhook-url
Description: Slack webhook for deployment notifications
```

#### Verification:

```bash
curl -X POST YOUR_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test notification from Jenkins"}'
```

---

### 6. Database Credentials

**ID:** `btd-database-credentials`
**Type:** Username with password
**Purpose:** Database migrations

#### Credential Details:

- **Host:** 10.27.27.30
- **Port:** 5432
- **Database:** btd_platform
- **Username:** btd_admin
- **Password:** [from database setup]

#### Adding to Jenkins:

```
Kind: Username with password
Scope: Global
Username: btd_admin
Password: [database password]
ID: btd-database-credentials
Description: PostgreSQL credentials for database migrations
```

#### Verification:

```bash
PGPASSWORD='YOUR_PASSWORD' psql \
  -h 10.27.27.30 \
  -U btd_admin \
  -d btd_platform \
  -c "SELECT version();"
```

---

### 7. Redis Password

**ID:** `btd-redis-password`
**Type:** Secret text
**Purpose:** Redis cache access
**Optional:** Yes (if Redis has no password, skip)

#### Adding to Jenkins:

```
Kind: Secret text
Scope: Global
Secret: [Redis password]
ID: btd-redis-password
Description: Redis password for cache access
```

#### Verification:

```bash
redis-cli -h 10.27.27.26 -a YOUR_PASSWORD ping
```

---

### 8. MinIO Credentials

**ID:** `minio-access-credentials`
**Type:** Username with password
**Purpose:** Object storage access

#### Credential Details:

- **Access Key:** minio_access_key
- **Secret Key:** [from MinIO setup]
- **Endpoint:** http://10.27.27.28:9000

#### Adding to Jenkins:

```
Kind: Username with password
Scope: Global
Username: [MinIO access key]
Password: [MinIO secret key]
ID: minio-access-credentials
Description: MinIO access credentials for object storage
```

#### Verification:

```bash
# Using mc (MinIO client)
mc alias set btd-minio http://10.27.27.28:9000 \
  ACCESS_KEY SECRET_KEY
mc ls btd-minio
```

---

## Adding Credentials

### Via Web UI:

1. Navigate to: `Manage Jenkins > Manage Credentials`
2. Click on domain (e.g., `(global)`)
3. Click "Add Credentials"
4. Fill in credential details
5. Click "OK"

### Via Jenkins CLI:

```bash
# Download Jenkins CLI
wget http://10.27.27.251:8080/jnlpJars/jenkins-cli.jar

# Add credential via XML
cat > credential.xml << EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>example-id</id>
  <description>Example credential</description>
  <username>user</username>
  <password>pass</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

java -jar jenkins-cli.jar -s http://10.27.27.251:8080/ \
  -auth admin:PASSWORD \
  create-credentials-by-xml system::system::jenkins _ < credential.xml
```

---

## Credential Types

### 1. Secret Text

Single secret value (API tokens, passwords)

```groovy
withCredentials([string(credentialsId: 'my-secret', variable: 'SECRET')]) {
    sh 'echo $SECRET'
}
```

### 2. Username with Password

Username and password pair

```groovy
withCredentials([usernamePassword(
    credentialsId: 'my-creds',
    usernameVariable: 'USER',
    passwordVariable: 'PASS'
)]) {
    sh 'echo $USER:$PASS'
}
```

### 3. SSH Username with Private Key

SSH key for authentication

```groovy
withCredentials([sshUserPrivateKey(
    credentialsId: 'my-ssh-key',
    keyFileVariable: 'SSH_KEY',
    usernameVariable: 'SSH_USER'
)]) {
    sh 'ssh -i $SSH_KEY $SSH_USER@host'
}
```

### 4. Certificate

X.509 certificate

```groovy
withCredentials([certificate(
    credentialsId: 'my-cert',
    keystoreVariable: 'CERT',
    passwordVariable: 'CERT_PASS'
)]) {
    sh 'use certificate'
}
```

---

## Security Best Practices

### 1. Credential Scope

- Use **Global** only when necessary
- Prefer **Project-specific** scope for production
- Never use **System** scope for application credentials

### 2. Credential Masking

All credential values are automatically masked in console output:

```
[INFO] Using credentials: ****
```

### 3. Audit Logging

Enable audit logging for credential access:

```
Manage Jenkins > Configure System > Audit Trail
```

### 4. Access Control

Limit who can:
- **View credentials:** Read access
- **Add/Modify credentials:** Configure access
- **Use credentials:** Execute access

### 5. Encryption

Credentials are encrypted using Jenkins master key:

```
/var/lib/jenkins/secrets/master.key
/var/lib/jenkins/secrets/hudson.util.Secret
```

**Backup these files securely!**

---

## Credential Rotation

### Rotation Schedule:

| Credential | Frequency | Priority |
|------------|-----------|----------|
| GitHub PAT | 90 days | High |
| Proxmox Token | 180 days | Medium |
| Ansible SSH Key | 365 days | Medium |
| Consul Token | 90 days | High |
| Database Password | 60 days (prod) | Critical |
| Slack Webhook | On compromise | Low |

### Rotation Process:

1. **Generate new credential** (don't delete old one yet)
2. **Add new credential to Jenkins** with new ID or update existing
3. **Test new credential** in non-production environment
4. **Update pipelines** to use new credential
5. **Deploy to production**
6. **Verify functionality**
7. **Revoke old credential**
8. **Document change**

### Automated Rotation (Advanced):

Use HashiCorp Vault integration for automatic rotation:

```bash
# Install Vault plugin
# Configure Vault connection
# Use dynamic credentials in pipelines
```

---

## Troubleshooting

### Credential Not Found

**Error:** `Credentials 'xxx' not found`

**Solution:**
1. Verify credential ID matches exactly
2. Check credential scope (global vs project)
3. Ensure credential exists in correct domain

### Permission Denied

**Error:** `User lacks permission to access credential`

**Solution:**
1. Check user permissions in Jenkins security
2. Verify credential scope includes the job
3. Grant "Use" permission for credentials

### Masked Credentials in Output

Credentials are intentionally masked. To debug:
1. Use `echo "Credential loaded"` instead of echoing value
2. Check Jenkins system log for errors
3. Verify credential format and content

### SSH Key Not Working

**Error:** `Permission denied (publickey)`

**Solution:**
```bash
# Check key permissions
ls -la /var/lib/jenkins/.ssh/

# Test SSH manually
ssh -i /var/lib/jenkins/.ssh/ansible_rsa -v root@10.27.27.100

# Verify public key is deployed
ssh root@10.27.27.100 "cat ~/.ssh/authorized_keys"
```

### Token Expired

**Error:** `401 Unauthorized`

**Solution:**
1. Generate new token
2. Update credential in Jenkins
3. Test new token
4. Update rotation calendar

---

## Credential Backup

### Backup Credentials Securely:

```bash
# Backup Jenkins credentials
sudo tar -czf jenkins-credentials-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/credentials.xml \
  /var/lib/jenkins/secrets/

# Encrypt backup
gpg --encrypt --recipient devops@btd-platform.com \
  jenkins-credentials-$(date +%Y%m%d).tar.gz

# Store encrypted backup securely
# Never store unencrypted backups!
```

---

## Next Steps

1. ✅ Add all required credentials to Jenkins
2. ✅ Test each credential
3. ✅ Set up credential rotation schedule
4. ✅ Configure audit logging
5. ✅ Document credential owners and rotation dates

---

**Last Updated:** 2025-10-10
**Version:** 1.0
**Security Classification:** RESTRICTED
**Maintained by:** BTD DevOps Team
