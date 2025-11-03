# Common Deployment Issues

**Last Updated**: 2025-11-03

## Issue: rsync Proto File Copy Failure

### Symptoms
```
rsync: [sender] change_dir "/var/jenkins/workspace/.../src/proto" failed: No such file or directory (2)
rsync error: some files/attrs were not transferred (code 23)
```

### Root Cause
Services using `@btd/proto` npm package don't have `src/proto/` directory. Proto files are in `node_modules/@btd/proto/` after npm ci.

### Solution
Remove proto copy section from Jenkinsfile. Proto files are automatically available from node_modules after npm ci.

**Fixed in**: 2025-11-03 (removed from all 18 service Jenkinsfiles)

---

## Issue: Database Authentication Failure

### Symptoms
```
PrismaClientInitializationError: Authentication failed against database server at `10.27.27.70`,
the provided database credentials for `postgres` are not valid.
```

### Root Cause
Ansible template using incorrect database credentials or wrong environment-specific user.

### Solution
1. Verify correct credentials in `credentials/MULTI-ENVIRONMENT-DATABASE-CREDENTIALS.md`
2. Check Ansible template has proper Jinja2 conditionals:
```jinja2
{% if environment_name == 'production' %}
DATABASE_URL=postgresql://[service]_user:[password]@10.27.27.70:5432/btd_[service]
{% elif environment_name == 'staging' %}
DATABASE_URL=postgresql://staging_[service]_user:[password]@10.27.27.70:5432/btd_[service]_staging
{% else %}
DATABASE_URL=postgresql://dev_[service]_user:[password]@10.27.27.70:5432/btd_[service]_dev
{% endif %}
```
3. Redeploy service to regenerate .env file

---

## Issue: Port Already in Use

### Symptoms
```
Error: No address added out of total 1 resolved
errors: [listen EADDRINUSE: address already in use 0.0.0.0:50053]
```

### Root Cause
Service trying to start while previous instance still running on the port.

### Solution
```bash
# SSH to service container
ssh root@10.27.26.84

# Stop service
systemctl stop btd-analytics-service

# Wait for port to be released
sleep 2

# Start service
systemctl start btd-analytics-service

# Verify
systemctl status btd-analytics-service
curl http://localhost:3003/api/v1/health
```

---

## Issue: Health Check Fails After Deployment

### Symptoms
```
curl: (7) Failed to connect to 10.27.26.84 port 3003: Connection refused
```

### Root Cause
Service crashed on startup due to configuration error, database connectivity, or missing dependencies.

### Diagnosis Steps

1. **Check systemd status:**
```bash
ssh root@10.27.26.84 "systemctl status btd-analytics-service"
```

2. **Check application logs:**
```bash
ssh root@10.27.26.84 "journalctl -u btd-analytics-service -n 100 --no-pager"
```

3. **Check .env file:**
```bash
ssh root@10.27.26.84 "cat /opt/btd/btd-analytics-service/.env"
```

4. **Test database connectivity:**
```bash
ssh root@10.27.26.84
cd /opt/btd/btd-analytics-service
node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient(); prisma.\$connect().then(() => console.log('DB OK')).catch(e => console.error(e))"
```

---

## Issue: Prisma Schema Mismatch

### Symptoms
```
Property 'X' does not exist on type 'Y'
Invalid prisma.model.findMany() invocation
```

### Root Cause
Prisma Client was generated against different schema version than what's in the database.

### Solution
```bash
# SSH to service container
ssh root@10.27.26.84

# Regenerate Prisma Client
cd /opt/btd/btd-analytics-service
npx prisma generate

# Restart service
systemctl restart btd-analytics-service
```

---

## Issue: Jenkins Build Stuck on "Building"

### Symptoms
Jenkins shows build as "in progress" but no console output for extended period.

### Diagnosis

1. **Check Jenkins agent status:**
```bash
ssh root@10.27.27.251
docker ps | grep jenkins-agent
```

2. **Check agent connectivity:**
```bash
# From Jenkins UI
Manage Jenkins → Nodes → jenkins-agent → Check "Log"
```

3. **Restart Jenkins agent:**
```bash
ssh root@10.27.27.60
docker restart jenkins-agent
```

---

## Issue: Ansible Playbook Hangs

### Symptoms
Ansible playbook stops responding during task execution.

### Diagnosis

1. **Check SSH connectivity:**
```bash
ssh -i ~/.ssh/id_ed25519_ansible root@10.27.26.84 "echo connected"
```

2. **Check for hung processes:**
```bash
ssh root@10.27.27.181  # Ansible LXC
ps aux | grep ansible
```

3. **Kill hung Ansible processes:**
```bash
pkill -9 -f ansible-playbook
```

---

## Issue: GitHub Webhook Not Triggering

### Symptoms
Push to GitHub doesn't trigger Jenkins build.

### Diagnosis

1. **Check webhook delivery in GitHub:**
   - Go to repository Settings → Webhooks
   - Click on webhook URL
   - Check "Recent Deliveries" tab

2. **Verify webhook URL:**
   - Should be: `https://jenkins.bknight.dev/github-webhook/`

3. **Test webhook manually:**
```bash
curl -X POST https://jenkins.bknight.dev/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{"repository":{"full_name":"btd-app/btd-analytics-service"},"ref":"refs/heads/develop"}'
```

---

## Issue: Service Running But Consul Shows Unhealthy

### Symptoms
Service health endpoint returns 200 OK, but Consul shows service as critical.

### Diagnosis

1. **Check Consul health definition:**
```bash
TOKEN="1278be15-88e1-8011-389a-b72b73ed3e49"
curl -H "X-Consul-Token: $TOKEN" \
  "http://10.27.27.27:8500/v1/health/service/btd-analytics-service"
```

2. **Verify service registration:**
```bash
ssh root@10.27.26.84
cd /opt/btd/btd-analytics-service
grep -A 10 "consul" src/main.ts
```

3. **Test health endpoint from Consul's perspective:**
```bash
# From Consul server
curl http://10.27.26.84:3003/api/v1/health
```

---

## Quick Reference: Diagnostic Commands

```bash
# Service status across all environments
for ip in 84 184 84; do
  echo "=== 10.27.26.$ip ==="
  ssh root@10.27.26.$ip "systemctl status btd-analytics-service | head -5"
done

# Check all Jenkins builds
curl -u 'btd-user:PASSWORD' \
  'http://10.27.27.251:8080/job/btd-microservices/api/json?tree=jobs[name,lastBuild[number,result]]'

# Check Consul service health
curl -H "X-Consul-Token: 1278be15-88e1-8011-389a-b72b73ed3e49" \
  "http://10.27.27.27:8500/v1/health/state/any"

# Database connectivity test
for env in dev staging prod; do
  echo "=== $env ==="
  PGPASSWORD='...' psql -h 10.27.27.70 -U ${env}_analytics_user -d btd_analytics_${env} -c "SELECT 1"
done
```

## See Also

- [Multi-Environment Deployment Guide](../deployment/multi-environment-guide.md)
- [Health Check Failures](health-check-failures.md)
- [Database Credentials](../../credentials/MULTI-ENVIRONMENT-DATABASE-CREDENTIALS.md)
