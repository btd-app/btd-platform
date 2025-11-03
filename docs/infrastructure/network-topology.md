# BTD Network Topology

**Last Updated**: 2025-11-03

## Overview

BTD infrastructure spans three network segments for environment isolation:

- **Development**: 10.27.26.80-97
- **Staging**: 10.27.26.180-197
- **Production**: 10.27.27.80-97

## Network Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      BTD Infrastructure                      │
│                        10.27.27.0/24                         │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐      ┌──────────────┐
│  Core Infra  │    │   Services   │      │   CI/CD      │
│  .70-.79     │    │   .80-.97    │      │   .251       │
└──────────────┘    └──────────────┘      └──────────────┘
│                   │                     │
│ PostgreSQL .70    │ btd-auth .80        │ Jenkins .251
│ Redis .71         │ btd-users .81       │ Ansible .181
│ MinIO .72         │ btd-messaging .82   │
│ Verdaccio .18     │ btd-matches .83     │
│ HAProxy .74       │ (18 services)       │
│ Monitoring .75    │                     │
└───────────────────┴─────────────────────┴──────────────┘
```

## Service Mesh

All BTD microservices use Consul for service discovery and health monitoring:

- **Consul Cluster**: 10.27.27.27, .115, .116
- **Service Registration**: Automatic on startup
- **Health Checks**: HTTP and gRPC endpoints

## Network Access

### SSH Access
- Jenkins → Ansible LXC: `~/.ssh/id_jenkins_to_ansible`
- Ansible → Service Containers: `~/.ssh/id_ed25519_ansible`

### Database Access
- Services connect to PostgreSQL (10.27.27.70:5432)
- Environment-specific users and databases
- md5 authentication via pg_hba.conf

### Service Communication
- **HTTP**: REST APIs for client-facing endpoints
- **gRPC**: Internal microservice communication
- **Port Ranges**:
  - HTTP: 3000-3020, 9130
  - gRPC: 50051-50068

## Firewall Rules

All services operate within Proxmox LXC containers with network isolation enforced at the hypervisor level.

## See Also

- [Service IP Mapping](service-ip-mapping.md)
- [Port Registry](port-registry.md)
