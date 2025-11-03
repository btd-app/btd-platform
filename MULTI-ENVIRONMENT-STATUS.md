# Multi-Environment IP Ranges - Current Status

## Summary

❌ **NOT IMPLEMENTED** - The different IP ranges for dev/staging/production are documented but not actually implemented in code.

## What's Documented vs What's Implemented

### Documentation Says:
(From `jenkins/README.md`)

| Environment | IP Range | Status |
|-------------|----------|--------|
| **Development** | 10.27.27.200-217 | 📄 Documented only |
| **Staging** | 10.27.27.150-167 | 📄 Documented only |
| **Production** | 10.27.27.100-117 | 📄 Documented only |

### Reality:

| Environment | IP Range | Status |
|-------------|----------|--------|
| **All (current)** | 10.27.27.80-97 | ✅ Actually deployed |

## Evidence

### 1. Terraform Configuration
`terraform/main.tf` has **hardcoded IPs**:

```hcl
resource "proxmox_virtual_environment_container" "auth_service" {
    initialization {
        ip_config {
            ipv4 {
                address = "10.27.27.82/23"  # ← Hardcoded, no environment logic
            }
        }
    }
}
```

**No environment-based logic**: The Terraform doesn't use variables, workspaces, or conditionals to change IPs based on environment.

### 2. Job DSL Configuration
`jenkins/jobs/btd_microservices_multibranch.groovy` has **single IPs**:

```groovy
def microservices = [
    [
        name: 'btd-auth-service',
        ip: '10.27.27.82',     # ← Single IP, not environment-aware
        httpPort: 3005,
    ],
    // ... 17 more services
]
```

**No branch-to-IP mapping**: Each service has ONE IP address, regardless of which branch is deployed.

### 3. Current Deployment Reality

All services currently deploy to the **same IP** regardless of branch:

```
btd-auth-service:
  ├── develop  → deploys to 10.27.27.82
  ├── staging  → deploys to 10.27.27.82  (same container!)
  └── main     → deploys to 10.27.27.82  (same container!)
```

This means all three environments **overwrite each other** on the same containers.

## What Would Be Required for True Multi-Environment

To implement the documented architecture, you would need:

### 1. Terraform Changes

**Option A: Terraform Workspaces**
```hcl
# Use workspace-based IP calculation
locals {
  env_offset = {
    development = 200
    staging     = 150
    production  = 100
  }
  base_offset = local.env_offset[terraform.workspace]
}

resource "proxmox_virtual_environment_container" "auth_service" {
    initialization {
        ip_config {
            ipv4 {
                address = "10.27.27.${local.base_offset + 2}/23"
                # development: 10.27.27.202
                # staging: 10.27.27.152
                # production: 10.27.27.102
            }
        }
    }
}
```

**Option B: Separate Terraform Directories**
```
terraform/
├── environments/
│   ├── development/
│   │   └── main.tf  (IPs: 10.27.27.200-217)
│   ├── staging/
│   │   └── main.tf  (IPs: 10.27.27.150-167)
│   └── production/
│       └── main.tf  (IPs: 10.27.27.80-97)
```

### 2. Job DSL Changes

Environment-aware IP mapping:

```groovy
def getServiceIP(serviceName, environment) {
    def baseIPs = [
        'btd-auth-service': 82,
        'btd-users-service': 86,
        // ...
    ]

    def envOffsets = [
        development: 200,
        staging: 150,
        production: 100
    ]

    def baseIP = baseIPs[serviceName]
    def offset = envOffsets[environment]

    return "10.27.27.${offset + baseIP - 80}"
}

// Then in Jenkinsfile, determine IP based on BRANCH_NAME
```

### 3. Ansible Inventory Changes

Separate inventories per environment:

```
btd-ansible/
├── inventories/
│   ├── development/
│   │   ├── hosts.yml  (10.27.27.200-217)
│   │   └── group_vars/
│   ├── staging/
│   │   ├── hosts.yml  (10.27.27.150-167)
│   │   └── group_vars/
│   └── production/
│       ├── hosts.yml  (10.27.27.80-97)
│       └── group_vars/
```

### 4. Pipeline Changes

Service Jenkinsfiles would need to:
- Detect branch name
- Map branch to environment
- Use correct IP range
- Deploy to environment-specific container

## Current Workflow (How It Actually Works)

```
Developer pushes to btd-auth-service/develop
         ↓
Pipeline deploys to 10.27.27.82
         ↓
Developer pushes to btd-auth-service/staging
         ↓
Pipeline deploys to 10.27.27.82 (OVERWRITES develop!)
         ↓
Developer pushes to btd-auth-service/main
         ↓
Pipeline deploys to 10.27.27.82 (OVERWRITES everything!)
```

**Result**: Only one version of each service can run at a time. The environments are not isolated.

## Why This Matters

**Current limitations**:
- ❌ Can't test staging without affecting production
- ❌ Can't run integration tests across environments
- ❌ No true pre-production validation
- ❌ Deployments to different branches conflict

**If multi-environment was implemented**:
- ✅ Isolated development/staging/production
- ✅ Safe testing before production
- ✅ Multiple versions running simultaneously
- ✅ True environment promotion workflow

## Recommendations

### Option 1: Implement Multi-Environment (High Effort)
- Refactor Terraform for environment-based IPs
- Update Job DSL with branch-to-IP mapping
- Create environment-specific Ansible inventories
- Update all 18 service Jenkinsfiles
- Provision 54 total containers (18 services × 3 environments)

**Estimated effort**: 2-3 weeks
**Infrastructure cost**: 3x current resources

### Option 2: Accept Single Environment (Current State)
- Document that only production exists
- Use feature flags for testing
- Deploy to production carefully
- Use blue/green or canary deployments within production

**Estimated effort**: Update documentation
**Infrastructure cost**: No change

### Option 3: Hybrid Approach
- Keep production as-is (10.27.27.80-97)
- Add single staging environment (10.27.27.150-167)
- Keep develop as local/CI only

**Estimated effort**: 1 week
**Infrastructure cost**: 2x current resources

## Status Summary

| Component | Multi-Environment Support | Notes |
|-----------|--------------------------|-------|
| Terraform | ❌ No | Hardcoded IPs |
| Job DSL | ❌ No | Single IP per service |
| Ansible | ⚠️ Partial | Has inventory structure but uses same IPs |
| Jenkinsfiles | ⚠️ Partial | Detects branch but deploys to same IP |
| Documentation | ✅ Yes | Documents 3 environments |
| **Actual Implementation** | ❌ **No** | **Single environment only** |

## Conclusion

The BTD platform currently operates as a **single environment** with hardcoded IPs in the range 10.27.27.80-97. The documentation describing separate dev/staging/production IP ranges represents a **future goal**, not the current implementation.

All branches (`develop`, `staging`, `main`) deploy to the same containers, meaning only one environment can run at a time.

---

**Date**: 2025-11-03
**Status**: Documented as-is
**Related**: See [ARCHITECTURE-OVERVIEW.md](./ARCHITECTURE-OVERVIEW.md)
