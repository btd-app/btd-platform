# Ceph Storage Migration Plan for BTD Infrastructure

## Current State
All 21 LXC containers are currently running on `local-lvm` storage across three Proxmox nodes:
- **pveserver2**: 7 containers
- **pves3**: 7 containers
- **pveserver4**: 7 containers

## Available Ceph Storage Pools
- **ssds** (RBD) - Fast SSD storage, ideal for databases and high-performance services
- **sixteen_tb_hdds** (RBD) - Large capacity HDD storage, ideal for object storage
- **one_point_two_tb_hdds** (RBD) - Medium capacity storage

## Migration Strategy

### Phase 1: Risk Assessment and Planning
1. **Backup all containers** before migration
2. **Test migration** with a non-critical service first
3. **Document rollback procedures** for each container
4. **Schedule maintenance windows** for critical services

### Phase 2: Service Categorization

#### Tier 1 - Critical Infrastructure (Migrate Last)
These services should be migrated last due to their critical nature:
- **postgres** (VMID 300) → Target: `ssds` (needs fast I/O)
- **redis** (VMID 301) → Target: `ssds` (needs fast I/O)
- **orchestrator** (VMID 327) → Target: `ssds` (API gateway)

#### Tier 2 - Object Storage (Special Consideration)
- **minio** (VMID 302) → Target: `sixteen_tb_hdds` (needs capacity over speed)

#### Tier 3 - Application Services (Migrate First)
These services can be migrated first with minimal risk:
- All other service containers → Target: `ssds`

### Phase 3: Migration Process

#### Pre-Migration Steps
```bash
# 1. Create full backup
vzdump <vmid> --compress gzip --storage backup-storage

# 2. Test container health
pct exec <vmid> -- systemctl status

# 3. Document current network configuration
pct config <vmid> > /backup/config-<vmid>.txt
```

#### Migration Commands
```bash
# Stop container
pct stop <vmid>

# Move rootfs to Ceph storage
pct move-disk <vmid> rootfs <target-storage> --delete

# Start container
pct start <vmid>

# Verify container
pct exec <vmid> -- systemctl status
```

#### Post-Migration Verification
```bash
# Check storage location
pct config <vmid> | grep rootfs

# Test application connectivity
curl http://<container-ip>:<port>/health

# Monitor performance
sar -d 1 10
```

### Phase 4: Terraform Configuration Update

After successful migration, update Terraform configuration:

1. **Update terraform.tfvars**:
```hcl
# Change from local-lvm to Ceph storage pools
storage_config = {
  databases = "ssds"
  cache     = "ssds"
  services  = "ssds"
  objects   = "sixteen_tb_hdds"
}
```

2. **Update main.tf** for each container:
```hcl
disk {
  datastore_id = "ssds"  # Changed from "local-lvm"
  size         = 20
}
```

3. **Run Terraform refresh**:
```bash
terraform refresh
terraform plan  # Should show no changes if migration successful
```

## Migration Schedule

### Week 1: Test Migration
- Migrate one non-critical service (e.g., btd-admin-01)
- Monitor for 48 hours
- Document any issues

### Week 2: Tier 3 Services
- Migrate all application services (except critical infrastructure)
- Services: auth, users, messaging, matches, analytics, etc.

### Week 3: Tier 2 Services
- Migrate MinIO to sixteen_tb_hdds
- Ensure adequate storage capacity

### Week 4: Tier 1 Services (Maintenance Window Required)
- Schedule 2-hour maintenance window
- Migrate PostgreSQL
- Migrate Redis
- Migrate Orchestrator

## Rollback Procedures

If migration fails:
1. Stop the container: `pct stop <vmid>`
2. Restore from backup: `pct restore <vmid> <backup-file>`
3. Start container: `pct start <vmid>`
4. Verify services are running

## Performance Considerations

### Expected Improvements with Ceph
- **High Availability**: Data replicated across nodes
- **Live Migration**: Containers can move between nodes without downtime
- **Better I/O Performance**: Especially for database workloads on SSD pool
- **Centralized Storage Management**: Easier to expand and manage

### Potential Challenges
- **Network Latency**: Ceph uses network for storage traffic
- **Initial Performance Tuning**: May need to adjust Ceph settings
- **Learning Curve**: Team needs familiarity with Ceph operations

## Monitoring During Migration

### Key Metrics to Watch
- **I/O Wait**: Should not exceed 20%
- **Network Throughput**: Monitor for saturation
- **Ceph Health**: `ceph -s` should show HEALTH_OK
- **Application Response Times**: Should not degrade

### Commands for Monitoring
```bash
# Ceph cluster health
ceph -s

# Ceph pool usage
ceph df

# Container I/O stats
pct exec <vmid> -- iostat -x 1

# Network statistics
iftop -i <ceph-network-interface>
```

## Success Criteria

Migration is considered successful when:
1. All containers running on Ceph storage
2. No performance degradation observed
3. Terraform state matches actual infrastructure
4. Successful failover test completed
5. Monitoring shows stable metrics for 7 days

## Emergency Contacts

- **Infrastructure Team**: [Contact Details]
- **Ceph Admin**: [Contact Details]
- **On-Call Engineer**: [Contact Details]

## Appendix: Automation Scripts

### Batch Migration Script
```bash
#!/bin/bash
# migrate-to-ceph.sh
# Migrates a container from local-lvm to Ceph storage

VMID=$1
TARGET_STORAGE=$2

if [ -z "$VMID" ] || [ -z "$TARGET_STORAGE" ]; then
    echo "Usage: $0 <vmid> <target-storage>"
    exit 1
fi

echo "Creating backup of container $VMID..."
vzdump $VMID --compress gzip --storage backup-storage

echo "Stopping container $VMID..."
pct stop $VMID

echo "Migrating storage to $TARGET_STORAGE..."
pct move-disk $VMID rootfs $TARGET_STORAGE --delete

echo "Starting container $VMID..."
pct start $VMID

echo "Migration complete. Verifying..."
pct config $VMID | grep rootfs
```

## Document Version
- **Version**: 1.0
- **Date**: 2025-10-10
- **Author**: Terraform Expert
- **Review Status**: Draft

## Next Steps
1. Review this plan with infrastructure team
2. Get approval for maintenance windows
3. Set up monitoring dashboards
4. Create detailed runbooks for each service migration
5. Schedule migration phases