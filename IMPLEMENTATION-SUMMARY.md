# BTD Platform Git-Based Infrastructure Workflow

## Implementation Summary
**Date**: 2025-11-03
**Status**: ✅ Core Implementation Complete

## What Was Accomplished

### ✅ Phase 1: Repository Setup
1. Created `/root/projects/` directory structure
2. Cloned `btd-app/btd-platform` repository from GitHub
3. Cloned `btd-app/btd-ansible` repository for Ansible playbooks
4. Updated `.gitignore` to exclude Terraform state files and credentials

### ✅ Phase 2: Code Migration
1. **Terraform Infrastructure** (`/var/lib/jenkins/terraform/` → `btd-platform/terraform/`)
   - All `.tf` configuration files
   - Modules for LXC containers and infrastructure
   - Variable files and documentation
   - **Excluded**: State files (using Consul backend)

2. **Jenkins Pipelines** (`/var/lib/jenkins/btd-pipelines/` → `btd-platform/jenkins/`)
   - Main Jenkinsfile (orchestrates full deployments)
   - Jenkinsfile.infrastructure (Terraform-only)
   - Jenkinsfile.application (Ansible-only)
   - Jenkinsfile.microservice.template (individual services)
   - Job DSL scripts for automated job creation
   - Deployment scripts (health checks, rollback, smoke tests)

3. **Pushed to GitHub**: All code committed and pushed to `main` branch

### ✅ Phase 3: Jenkins Configuration Updates
1. Updated `btd-seed-job` to reference `/root/projects/btd-platform/jenkins/jobs/`
2. Updated all Jenkinsfile environment variables:
   - `BTD_APP_ROOT`: `/root/projects/btd-app` → `/root/projects/btd-platform`
   - `ANSIBLE_DIR`: Now points to `/root/projects/btd-ansible` (separate repo)
   - `TERRAFORM_DIR`: `${BTD_APP_ROOT}/terraform`
   - `JENKINS_DIR`: `${BTD_APP_ROOT}/jenkins`

### ✅ Phase 4: Git Sync Workflow
1. Created `btd-platform-sync` Jenkins job
2. Configured job to:
   - Pull latest changes from GitHub
   - Sync to `/root/projects/btd-platform`
   - Trigger `btd-seed-job` to regenerate pipeline jobs
3. Tested git pull workflow successfully ✓

### ✅ Phase 5: GitHub Webhook Integration
1. Created webhook in GitHub repository
2. Webhook URL: `https://jenkins.bknight.dev/github-webhook/`
3. Webhook successfully reaching Jenkins (HTTP 200 responses)
4. GitHub logs show successful deliveries

## Current Architecture

```
/root/projects/
├── btd-platform/              # Main infrastructure repo (synced from GitHub)
│   ├── terraform/             # Infrastructure as Code
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   └── modules/
│   ├── jenkins/               # CI/CD pipelines
│   │   ├── Jenkinsfile*
│   │   ├── jobs/             # Job DSL scripts
│   │   └── scripts/          # Deployment automation
│   └── docs/                  # Documentation
└── btd-ansible/               # Ansible playbooks (separate repo)
    ├── playbooks/
    ├── roles/
    └── inventories/
```

## Manual Sync Process (Working)

```bash
# Sync from GitHub to Jenkins
cd /root/projects/btd-platform
git pull origin main

# Regenerate Jenkins jobs
# Run btd-seed-job from Jenkins UI
```

## Outstanding Items

### 🔧 Webhook Auto-Trigger (Needs UI Debugging)
The GitHub webhook reaches Jenkins successfully, but automatic build triggers need troubleshooting:
- Webhook events: ✅ Received (`PushEvent` logged)
- Jenkins recognition: ✅ "Poked btd-platform-sync"
- Build trigger: ⚠️ Not starting automatically

**Possible causes**:
- GitHub plugin configuration in Jenkins global settings
- Build queue issues
- Permission/credential problems

**Workaround**: Manual sync works perfectly via git pull

### 📋 Recommended Next Steps
1. Access Jenkins UI at `https://jenkins.bknight.dev`
2. Check `btd-platform-sync` job configuration
3. Review build queue and logs
4. Verify GitHub plugin global settings
5. Test manual build trigger from UI

### 🗄️ Original Directory Backup
Original files remain at:
- `/var/lib/jenkins/btd-pipelines/` (can be archived after verification)
- `/var/lib/jenkins/terraform/` (can be archived after verification)

**Recommendation**: Keep for 30 days, then archive

## Benefits Achieved

1. **Version Control**: All infrastructure code in Git
2. **Collaboration**: Multiple team members can contribute via PRs
3. **History**: Full audit trail of infrastructure changes
4. **Rollback**: Easy revert to previous versions
5. **Documentation**: README and guides in repository
6. **Reproducibility**: Infrastructure as code is portable

## How to Use

### Making Infrastructure Changes
```bash
# 1. Make changes in repository
cd /root/projects/btd-platform
vim terraform/main.tf  # or jenkins/Jenkinsfile, etc.

# 2. Commit and push
git add .
git commit -m "Description of changes"
git push origin main

# 3. Sync to Jenkins (manual for now)
git pull origin main  # if editing remotely

# 4. Regenerate Jenkins jobs if Job DSL changed
# Run btd-seed-job from Jenkins UI
```

### Deploying Services
```bash
# Use Jenkins pipelines (paths now point to git repo)
# Main deployment: /root/projects/btd-platform/jenkins/Jenkinsfile
# Infrastructure only: /root/projects/btd-platform/jenkins/Jenkinsfile.infrastructure
# Application only: /root/projects/btd-platform/jenkins/Jenkinsfile.application
```

## Files and Paths Reference

| Purpose | Old Path | New Path |
|---------|----------|----------|
| Terraform configs | `/var/lib/jenkins/terraform/` | `/root/projects/btd-platform/terraform/` |
| Jenkins pipelines | `/var/lib/jenkins/btd-pipelines/` | `/root/projects/btd-platform/jenkins/` |
| Ansible playbooks | N/A | `/root/projects/btd-ansible/` |
| Job DSL scripts | `/var/lib/jenkins/btd-pipelines/jobs/` | `/root/projects/btd-platform/jenkins/jobs/` |

## Success Criteria Met

- ✅ Infrastructure code in version control
- ✅ Git clone workflow instead of manual file management
- ✅ Jenkins references git repository paths
- ✅ Manual sync tested and working
- ✅ GitHub webhook configured (needs auto-trigger debugging)
- ✅ Documentation complete

## Contact

For questions or issues with this implementation:
1. Check this documentation
2. Review Jenkins job configurations
3. Check `/root/projects/btd-platform/` for latest code

---

**Implementation completed by**: Claude Code
**Date**: 2025-11-03
**Repository**: https://github.com/btd-app/btd-platform
