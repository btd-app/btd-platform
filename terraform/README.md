# BTD Application - Terraform Infrastructure

This directory contains the Terraform configuration for provisioning the BTD application infrastructure on Proxmox VE.

## Overview

The configuration provisions 24 LXC containers:
- **6 Infrastructure containers**: Redis, PostgreSQL, Consul, MinIO, RabbitMQ, Monitoring
- **18 Service containers**: All BTD microservices

## Quick Start

### Prerequisites

1. Proxmox VE server (v8.0+)
2. Terraform v1.5.0+
3. Debian 12 LXC template available in Proxmox storage
4. Network bridge (vmbr0) configured
5. API credentials for Proxmox

### Usage

1. **Initialize Terraform**:
```bash
terraform init
```

2. **Set credentials** (environment variables):
```bash
export TF_VAR_proxmox_api_password="your-password"
export TF_VAR_consul_token="your-consul-token"  # Optional
```

3. **Review the plan**:
```bash
terraform plan
```

4. **Apply configuration**:
```bash
terraform apply
```

## Configuration Structure

```
terraform/
├── main.tf                 # Root module configuration
├── variables.tf            # Input variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Default variable values
├── providers.tf            # Provider configurations
├── backend.tf              # State backend (Consul)
└── modules/
    ├── lxc-container/      # Generic LXC container module
    └── infrastructure/     # Infrastructure containers module
```

## Network Layout

| Container Type | IP Range | Container Count |
|---------------|----------|-----------------|
| Infrastructure | 10.0.1.10-15 | 6 |
| Services | 10.0.1.20-37 | 18 |

## Container Specifications

### Infrastructure Containers
- **CPU**: 2 cores
- **Memory**: 2048 MB
- **Swap**: 512 MB
- **Disk**: 20 GB

### Service Containers
- **CPU**: 1 core
- **Memory**: 1024 MB
- **Swap**: 256 MB
- **Disk**: 10 GB

## State Management

The configuration uses Consul backend for state storage in production. For local development, you can switch to local backend by modifying `backend.tf`.

## Customization

Edit `terraform.tfvars` to customize:
- Network configuration
- Container resources
- Container template
- Environment settings

## Module Documentation

### lxc-container
Generic module for creating LXC containers with standardized configuration.

**Inputs**:
- `node_name` - Proxmox node
- `vm_id` - Container ID
- `description` - Container description
- `ip_address` - Container IP with CIDR
- Additional resource and network settings

**Outputs**:
- `container_id` - Container VM ID
- `ip_address` - Assigned IP address
- `mac_address` - Network MAC address

### infrastructure
Module for creating infrastructure containers with predefined configurations.

**Creates**:
- Redis container
- PostgreSQL container
- Consul container
- MinIO container
- RabbitMQ container
- Monitoring container

## Import Existing Infrastructure

If you have existing containers to import:

```bash
# Example: Import Redis container (ID 200)
terraform import module.infrastructure.module.infrastructure_containers[\"redis\"].proxmox_virtual_environment_container.container 200
```

## Validation

Run validation checks:
```bash
terraform validate
terraform fmt -check -recursive
```

## Security Notes

- Never commit credentials to version control
- Use environment variables or secure vaults for sensitive data
- The `.gitignore` file excludes sensitive files
- Consider using Terraform Cloud for team environments

## Support

For issues or questions about this Terraform configuration:
1. Check the VALIDATION-REPORT.md for validation status
2. Review the provider documentation: https://registry.terraform.io/providers/bpg/proxmox/latest
3. Consult the BTD infrastructure team

## License

This configuration is part of the BTD application infrastructure.