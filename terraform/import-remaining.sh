#!/bin/bash
# Import remaining containers

echo "Importing remaining containers..."

# MinIO
terraform import proxmox_virtual_environment_container.minio pveserver4/302

# Verdaccio
terraform import proxmox_virtual_environment_container.verdaccio pveserver2/303

# HAProxy
terraform import proxmox_virtual_environment_container.haproxy pves3/304

# Monitoring
terraform import proxmox_virtual_environment_container.monitoring pveserver4/305

# Orchestrator
terraform import proxmox_virtual_environment_container.orchestrator pveserver2/310

# Auth
terraform import proxmox_virtual_environment_container.auth pveserver2/311

# Users
terraform import proxmox_virtual_environment_container.users pves3/312

# Permission
terraform import proxmox_virtual_environment_container.permission pveserver4/313

# Notification
terraform import proxmox_virtual_environment_container.notification pveserver2/314

# Messaging
terraform import proxmox_virtual_environment_container.messaging pves3/315

# Moderation
terraform import proxmox_virtual_environment_container.moderation pveserver4/316

# Matches
terraform import proxmox_virtual_environment_container.matches pveserver2/317

# Location
terraform import proxmox_virtual_environment_container.location pves3/318

# Travel
terraform import proxmox_virtual_environment_container.travel pveserver4/319

# Payment
terraform import proxmox_virtual_environment_container.payment pveserver2/320

# Analytics
terraform import proxmox_virtual_environment_container.analytics pves3/321

# AI
terraform import proxmox_virtual_environment_container.ai pveserver4/322

# Video Call
terraform import proxmox_virtual_environment_container.video_call pveserver2/323

# Admin
terraform import proxmox_virtual_environment_container.admin pves3/324

# Job Processing
terraform import proxmox_virtual_environment_container.job_processing pveserver4/325

# File Processing
terraform import proxmox_virtual_environment_container.file_processing pveserver2/326

# Match Limits
terraform import proxmox_virtual_environment_container.match_limits pves3/327

echo "Import complete!"