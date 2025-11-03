# BTD Multi-Environment Database Credentials

**Generated**: 2025-11-03
**Status**: ACTIVE - Multi-environment isolation configured

## Overview

Each BTD service has isolated database credentials per environment:
- **Development** (10.27.26.x): `dev_[service]_user`
- **Staging** (10.27.26.1xx): `staging_[service]_user`
- **Production** (10.27.27.x): `[service]_user`

## Analytics Service Credentials

### Development Environment
```
Database Server: 10.27.27.70:5432
Database: btd_analytics_dev
User: dev_analytics_user
Password: DevAnalytics2025Track3M9x7Kp
Connection String: postgresql://dev_analytics_user:DevAnalytics2025Track3M9x7Kp@10.27.27.70:5432/btd_analytics_dev?schema=public
```

**Test Connection:**
```bash
PGPASSWORD='DevAnalytics2025Track3M9x7Kp' psql -h 10.27.27.70 -U dev_analytics_user -d btd_analytics_dev
```

### Staging Environment
```
Database Server: 10.27.27.70:5432
Database: btd_analytics_staging
User: staging_analytics_user
Password: StgAnalytics2025Insight8N2y4Qr
Connection String: postgresql://staging_analytics_user:StgAnalytics2025Insight8N2y4Qr@10.27.27.70:5432/btd_analytics_staging?schema=public
```

**Test Connection:**
```bash
PGPASSWORD='StgAnalytics2025Insight8N2y4Qr' psql -h 10.27.27.70 -U staging_analytics_user -d btd_analytics_staging
```

### Production Environment
```
Database Server: 10.27.27.70:5432
Database: btd_analytics
User: analytics_user
Password: Analytics2025Track8D3m5Vw
Connection String: postgresql://analytics_user:Analytics2025Track8D3m5Vw@10.27.27.70:5432/btd_analytics?schema=public
```

**Test Connection:**
```bash
PGPASSWORD='Analytics2025Track8D3m5Vw' psql -h 10.27.27.70 -U analytics_user -d btd_analytics
```

## Ansible Template Integration

The Ansible template automatically selects the correct credentials based on the `environment_name` variable:

**Location**: `/root/btd-infrastructure/ansible/templates/btd-analytics.env.j2`

```jinja2
{% if environment_name == 'production' %}
DATABASE_URL=postgresql://analytics_user:Analytics2025Track8D3m5Vw@{{ postgres_host }}:{{ postgres_port }}/btd_analytics?schema=public
{% elif environment_name == 'staging' %}
DATABASE_URL=postgresql://staging_analytics_user:StgAnalytics2025Insight8N2y4Qr@{{ postgres_host }}:{{ postgres_port }}/btd_analytics_staging?schema=public
{% else %}
DATABASE_URL=postgresql://dev_analytics_user:DevAnalytics2025Track3M9x7Kp@{{ postgres_host }}:{{ postgres_port }}/btd_analytics_dev?schema=public
{% endif %}
```

## Jenkins Deployment

Jenkins automatically deploys to the correct environment based on branch:
- `develop` branch → Development environment (10.27.26.84)
- `staging` branch → Staging environment (10.27.26.184)
- `main` branch → Production environment (10.27.27.84)

The Ansible playbook uses these credentials automatically through the template system.

## Security Notes

- ✅ Each environment has isolated database users
- ✅ Passwords are URL-safe (no special shell characters)
- ✅ Each user only has access to their specific database
- ✅ Connection strings are environment-specific
- ✅ Credentials stored in secure Ansible templates (not in git)

## Database Access Control

PostgreSQL host-based authentication (`pg_hba.conf`) allows:
- Development: 10.27.26.0/24 network
- Production: 10.27.27.0/24 network
- Staging uses development network (10.27.26.0/24)

## Troubleshooting

### Test Database Connection
```bash
# Development
PGPASSWORD='DevAnalytics2025Track3M9x7Kp' psql -h 10.27.27.70 -U dev_analytics_user -d btd_analytics_dev -c "SELECT version();"

# Staging
PGPASSWORD='StgAnalytics2025Insight8N2y4Qr' psql -h 10.27.27.70 -U staging_analytics_user -d btd_analytics_staging -c "SELECT version();"

# Production
PGPASSWORD='Analytics2025Track8D3m5Vw' psql -h 10.27.27.70 -U analytics_user -d btd_analytics -c "SELECT version();"
```

### Check Service .env File
```bash
# Development
ssh root@10.27.26.84 "grep DATABASE_URL /opt/btd/btd-analytics-service/.env"

# Staging
ssh root@10.27.26.184 "grep DATABASE_URL /opt/btd/btd-analytics-service/.env"

# Production
ssh root@10.27.27.84 "grep DATABASE_URL /opt/btd/btd-analytics-service/.env"
```

## Next Steps for Other Services

To configure multi-environment database credentials for other services:

1. **Create database users** (on 10.27.27.70):
   ```sql
   CREATE USER dev_[service]_user WITH PASSWORD '[password]';
   CREATE DATABASE btd_[service]_dev OWNER dev_[service]_user;

   CREATE USER staging_[service]_user WITH PASSWORD '[password]';
   CREATE DATABASE btd_[service]_staging OWNER staging_[service]_user;
   ```

2. **Update Ansible template** at `/root/btd-infrastructure/ansible/templates/btd-[service].env.j2`:
   - Add `{% if environment_name == 'production' %}` blocks for each environment
   - Use appropriate username, password, and database name for each

3. **Test deployment** through Jenkins on develop branch first

4. **Document credentials** in this file

---

**Last Updated**: 2025-11-03
**Updated By**: Claude Code (Automated)
