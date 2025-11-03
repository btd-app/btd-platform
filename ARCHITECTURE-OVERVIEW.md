# BTD Platform Architecture: Infrastructure + Microservices Integration

## Two-Layer Architecture

The BTD platform uses a **two-layer architecture** where infrastructure and application code are managed separately:

### Layer 1: Infrastructure (btd-platform Repository)
**Repository**: `btd-app/btd-platform`
**Purpose**: Platform foundation and deployment automation
**Location**: `/root/projects/btd-platform`

### Layer 2: Application (18 Microservice Repositories)
**Repositories**: `btd-app/btd-auth-service`, `btd-app/btd-users-service`, etc.
**Purpose**: Individual service application code
**Managed by**: Independent multibranch pipelines

---

## How They Work Together

```
┌─────────────────────────────────────────────────────────────────────┐
│                     LAYER 1: INFRASTRUCTURE                          │
│                    (btd-platform repository)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  📁 terraform/                                                       │
│  ├── Provisions 18 LXC containers (10.27.27.80-97)                  │
│  ├── Creates network configuration                                   │
│  └── Sets up infrastructure services (PostgreSQL, Redis, etc.)       │
│                                                                       │
│  📁 jenkins/jobs/                                                    │
│  ├── btd_microservices_multibranch.groovy ◄─ CREATES JOBS BELOW    │
│  │   • Defines service metadata (IP, ports, migrations)              │
│  │   • Creates 18 multibranch pipeline jobs                         │
│  │   • Configures GitHub integration per service                     │
│  │                                                                    │
│  └── btd_main_deployment.groovy                                      │
│      • Orchestrates full platform deployments                        │
│      • Coordinates Terraform + Ansible                               │
│                                                                       │
│  📁 jenkins/scripts/                                                 │
│  └── Shared deployment scripts (health checks, rollback, etc.)       │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ CREATES & CONFIGURES
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│              LAYER 2: APPLICATION MICROSERVICES                      │
│                  (18 separate repositories)                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Jenkins Jobs Created by Job DSL:                                    │
│                                                                       │
│  📦 btd-microservices/btd-auth-service                              │
│     ├── Branch: develop  → Deploy to 10.27.27.82 (dev)             │
│     ├── Branch: staging  → Deploy to 10.27.27.82 (staging)          │
│     └── Branch: main     → Deploy to 10.27.27.82 (production)       │
│                                                                       │
│  📦 btd-microservices/btd-users-service                             │
│     ├── Branch: develop  → Deploy to 10.27.27.86 (dev)             │
│     ├── Branch: staging  → Deploy to 10.27.27.86 (staging)          │
│     └── Branch: main     → Deploy to 10.27.27.86 (production)       │
│                                                                       │
│  📦 [... 16 more services ...]                                       │
│                                                                       │
│  Each service repo contains:                                         │
│  ├── Jenkinsfile (service-specific deployment logic)                │
│  ├── src/ (application code)                                         │
│  ├── package.json                                                    │
│  └── tests/                                                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ DEPLOYED VIA
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        ANSIBLE LAYER                                 │
│                   (btd-ansible repository)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Location: /root/projects/btd-ansible                               │
│                                                                       │
│  📁 playbooks/                                                       │
│  ├── deploy-independent-service.yml ◄─ Used by microservices       │
│  ├── deploy-btd-platform.yml        ◄─ Full platform deployment     │
│  └── health-check.yml                                                │
│                                                                       │
│  📁 inventories/                                                     │
│  ├── production/                                                     │
│  ├── staging/                                                        │
│  └── development/                                                    │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## The Workflow

### Infrastructure Changes (btd-platform)

```
Developer pushes to btd-platform
         ↓
GitHub webhook → Jenkins
         ↓
btd-platform-sync job runs
         ↓
Updates /root/projects/btd-platform
         ↓
Triggers btd-seed-job
         ↓
Regenerates all 18 microservice pipeline jobs
         ↓
Updates job configurations (IPs, ports, metadata)
```

**What gets updated:**
- Terraform configs (infrastructure provisioning)
- Jenkins Job DSL (pipeline definitions)
- Deployment scripts (shared automation)
- Service metadata (IP addresses, ports)

**When to update btd-platform:**
- Adding/removing a microservice
- Changing infrastructure (new LXC container)
- Updating deployment automation
- Modifying IP addresses or ports
- Changing Jenkins pipeline structure

---

### Application Changes (Individual Microservices)

```
Developer pushes to btd-auth-service/develop
         ↓
GitHub webhook → Jenkins
         ↓
btd-microservices/btd-auth-service/develop job runs
         ↓
Builds the service (npm install, tests, build)
         ↓
Deploys ONLY btd-auth-service to development environment
         ↓
Runs health checks on 10.27.27.82
         ↓
✓ Deployment complete (NO other services affected)
```

**What gets deployed:**
- Application code for that ONE service
- Database migrations (if service has `hasMigrations: true`)
- Service configuration
- Environment variables

**Independent deployment means:**
- Each service deploys separately
- No cross-service triggers
- Each service has its own pipeline
- Branch determines environment:
  - `develop` → Development environment
  - `staging` → Staging environment
  - `main` → Production environment (may require approval)

---

## Key Integration Points

### 1. Job DSL Creates Pipelines

The `btd_microservices_multibranch.groovy` file in btd-platform **creates** the pipeline jobs for all 18 services:

```groovy
// From btd-platform/jenkins/jobs/btd_microservices_multibranch.groovy

def microservices = [
    [
        name: 'btd-auth-service',
        ip: '10.27.27.82',        ← Used for deployment
        httpPort: 3005,
        grpcPort: 50051,
        hasMigrations: true       ← Determines if migrations run
    ],
    // ... 17 more services
]

microservices.each { service ->
    multibranchPipelineJob("btd-microservices/${service.name}") {
        // Creates job at: btd-microservices/btd-auth-service
        branchSources {
            github {
                repoOwner('btd-app')
                repository(service.name)  ← Points to service repo
            }
        }
    }
}
```

### 2. Service Jenkinsfiles Use Infrastructure Data

Each microservice repository has its own `Jenkinsfile` that uses the infrastructure metadata:

```groovy
// From individual service repos (e.g., btd-auth-service/Jenkinsfile)

pipeline {
    environment {
        SERVICE_NAME = 'btd-auth-service'
        SERVICE_IP = '10.27.27.82'     ← From Job DSL metadata
        SERVICE_PORT = '3005'
        ANSIBLE_PLAYBOOK = '/root/projects/btd-ansible/playbooks/deploy-independent-service.yml'
    }

    stages {
        stage('Build') {
            // Build this service only
        }

        stage('Deploy') {
            steps {
                // Deploy to the container specified by SERVICE_IP
                sh "ansible-playbook ${ANSIBLE_PLAYBOOK} -e service_name=${SERVICE_NAME}"
            }
        }
    }
}
```

### 3. Ansible Deploys to Containers

The Ansible playbooks deploy services to the containers provisioned by Terraform:

```yaml
# From btd-ansible/playbooks/deploy-independent-service.yml

- hosts: "{{ service_name }}"    # Matches service hostname
  vars:
    service_ip: "{{ hostvars[service_name].ansible_host }}"
  tasks:
    - name: Deploy service
      # Deploys to the LXC container at service_ip
```

---

## Environment Mapping

| Branch | Environment | IP Range | Auto-Deploy | Notes |
|--------|-------------|----------|-------------|-------|
| `develop` | Development | 10.27.26.80-97 | Yes | Automatic on push |
| `staging` | Staging | 10.27.26.180-197 | Yes | Automatic on push |
| `main` | Production | 10.27.27.80-97 | Manual approval | Current active range |

**Current Note**: Documentation shows multi-environment IP ranges, but actual implementation uses single range (10.27.27.80-97). Environment separation would require Terraform refactoring.

---

## Dependency Flow

```
btd-platform (infrastructure layer)
    ↓ defines
Jenkins Job DSL scripts
    ↓ creates
18 Multibranch Pipeline Jobs
    ↓ monitors
18 GitHub Service Repositories
    ↓ triggers on push
Service-specific Jenkinsfile
    ↓ calls
Ansible playbooks (btd-ansible)
    ↓ deploys to
LXC Containers (provisioned by Terraform)
```

---

## When to Use Each Repository

### Use `btd-platform` when:
- Adding a new microservice to the platform
- Changing service IPs or ports
- Modifying Jenkins pipeline structure
- Updating deployment automation (scripts, health checks)
- Provisioning new infrastructure
- Changing Terraform configurations

### Use individual service repos (e.g., `btd-auth-service`) when:
- Developing new features for that service
- Fixing bugs in that service
- Updating dependencies for that service
- Running service-specific tests
- Deploying ONLY that service

### Use `btd-ansible` when:
- Updating deployment playbooks
- Modifying Ansible roles
- Changing service configuration templates
- Updating inventory management

---

## Example Scenarios

### Scenario 1: Adding a New Microservice

1. **Add to Terraform** (`btd-platform/terraform/main.tf`):
   ```hcl
   resource "proxmox_virtual_environment_container" "new_service" {
       ip_address = "10.27.27.98"
   }
   ```

2. **Add to Job DSL** (`btd-platform/jenkins/jobs/btd_microservices_multibranch.groovy`):
   ```groovy
   [
       name: 'btd-new-service',
       ip: '10.27.27.98',
       httpPort: 3019,
       grpcPort: 50069
   ]
   ```

3. **Commit and push** to `btd-platform`

4. **Run** `btd-seed-job` to create the new pipeline

5. **Create** the service repository at `btd-app/btd-new-service`

6. **Push code** to service repo → automatic deployment

### Scenario 2: Deploying a Feature to One Service

1. **Develop** in `btd-auth-service` repository

2. **Push to** `develop` branch

3. **Automatic deployment** to development environment (10.27.27.82)

4. **Test**, then merge to `staging`

5. **Automatic deployment** to staging

6. **Merge to** `main` for production deployment

**Other services**: Completely unaffected ✓

---

## Summary

The btd-platform repository is the **infrastructure foundation** that:
- Provisions the LXC containers (Terraform)
- Creates the Jenkins pipeline jobs (Job DSL)
- Provides shared deployment automation (Scripts)
- Defines service metadata (IPs, ports, configuration)

The individual microservice repositories are the **application layer** that:
- Contain the actual service code
- Have independent deployment pipelines
- Deploy to containers provisioned by btd-platform
- Use Ansible playbooks from btd-ansible

**Key Principle**: Infrastructure changes go to `btd-platform`, application changes go to individual service repos. This separation allows infrastructure updates without redeploying services, and service updates without touching infrastructure.

---

**Last Updated**: 2025-11-03
**Related Documentation**:
- [Implementation Summary](./IMPLEMENTATION-SUMMARY.md)
- [Multi-Environment Guide](./docs/deployment/multi-environment-guide.md)
- [Service IP Mapping](./docs/infrastructure/service-ip-mapping.md)
