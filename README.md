# BTD Platform Infrastructure

**Central repository for BTD infrastructure documentation, deployment guides, and operational procedures**

## Repository Purpose

This repository contains all infrastructure-related documentation for the BTD (Better Than Dating) platform. It serves as the single source of truth for:

- Database credentials across all environments
- Deployment procedures and automation
- Infrastructure architecture and network topology
- Troubleshooting guides and runbooks
- CI/CD pipeline configuration

## Quick Links

### Credentials (Secure Documentation)
- [Multi-Environment Database Credentials](credentials/MULTI-ENVIRONMENT-DATABASE-CREDENTIALS.md)
- [Jenkins Access Credentials](credentials/JENKINS-CREDENTIALS.md)
- [Ansible SSH Keys](credentials/ANSIBLE-SSH-KEYS.md)

### Deployment Guides
- [Multi-Environment Deployment Guide](docs/deployment/multi-environment-guide.md)
- [Jenkins Pipeline Guide](docs/deployment/jenkins-pipeline-guide.md)
- [Ansible Playbook Guide](docs/deployment/ansible-playbook-guide.md)

### Infrastructure
- [Network Topology](docs/infrastructure/network-topology.md)
- [Service IP Mapping](docs/infrastructure/service-ip-mapping.md)
- [Port Registry](docs/infrastructure/port-registry.md)

### Troubleshooting
- [Common Deployment Issues](docs/troubleshooting/common-deployment-issues.md)
- [Health Check Failures](docs/troubleshooting/health-check-failures.md)

## Repository Structure

```
btd-platform/
├── README.md                           # This file
├── docs/
│   ├── deployment/                     # Deployment procedures and automation
│   ├── infrastructure/                 # Architecture, network, and system design
│   └── troubleshooting/                # Problem resolution guides
├── credentials/                        # Secure credential documentation
├── ansible/documentation/              # Ansible-specific documentation
├── jenkins/documentation/              # Jenkins CI/CD documentation
└── terraform/documentation/            # Infrastructure as Code documentation
```

## Infrastructure Overview

### Environment Architecture

BTD operates across three isolated environments:

| Environment | Network Range | Purpose | Auto-Deploy |
|------------|---------------|---------|-------------|
| **Development** | 10.27.26.80-97 | Active development and testing | Yes (develop branch) |
| **Staging** | 10.27.26.180-197 | Pre-production validation | Yes (staging branch) |
| **Production** | 10.27.27.80-97 | Live production services | Manual approval (main branch) |

### Core Infrastructure Services

| Service | IP Address | Purpose |
|---------|-----------|---------|
| Jenkins CI/CD | 10.27.27.251 | Automated deployment pipeline |
| Ansible LXC | 10.27.27.181 | Configuration management and deployment |
| PostgreSQL | 10.27.27.70 | Primary database server |
| Redis | 10.27.27.71 | Caching and pub/sub |
| Consul Cluster | 10.27.27.27, .115, .116 | Service discovery and health monitoring |
| MinIO | 10.27.27.72 | Object storage |
| Verdaccio | 10.27.27.18:4873 | Private npm registry |

### Deployment Flow

```
Developer Push to GitHub
         ↓
   GitHub Webhook
         ↓
Jenkins (10.27.27.251)
         ↓ SSH
Ansible LXC (10.27.27.181)
         ↓ ansible-playbook
BTD Service Containers (Environment-specific)
```

### Branch-to-Environment Mapping

- **develop** branch → Development environment (10.27.26.x)
- **staging** branch → Staging environment (10.27.26.1xx)
- **main** branch → Production environment (10.27.27.x) with manual approval

## Security Notes

1. **Credential Management**: All credentials in this repository are documented for operational purposes. Never commit actual secrets to git. Use secure vaults in production.

2. **Access Control**: This repository should have restricted access. Only infrastructure and DevOps team members should have write access.

3. **Network Isolation**: Each environment is network-isolated with separate database users and credentials.

4. **SSH Keys**: All SSH keys used by Jenkins and Ansible are documented but the actual private keys are stored securely on the respective servers.

## Contributing

When adding new infrastructure documentation:

1. Follow the existing directory structure
2. Use clear, concise markdown formatting
3. Include practical examples and commands
4. Add links to the Quick Links section in this README
5. Document any new credentials in the appropriate credentials file

## Related Repositories

- **btd-shared**: Shared libraries and utilities (`@btd/shared`, `@btd/proto`)
- **btd-analytics-service**: Analytics microservice
- **btd-auth-service**: Authentication microservice
- **btd-users-service**: User management microservice
- *(18 total microservices)*

## Support

For infrastructure issues or questions:

1. Check the [Troubleshooting Guides](docs/troubleshooting/)
2. Review [Common Deployment Issues](docs/troubleshooting/common-deployment-issues.md)
3. Consult the relevant credential documentation in `credentials/`

## Last Updated

**Date**: 2025-11-03
**Updated By**: Infrastructure Team (Automated via Claude Code)

---

**Note**: This repository is part of the BTD platform infrastructure. Handle all credential documentation with care and follow security best practices.
