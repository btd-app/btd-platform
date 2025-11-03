# BTD Application Infrastructure - Import Configuration
# Configuration matched to ACTUAL existing containers for zero-drift import
# After successful import, can be enhanced with additional features
# Provider configuration is in providers.tf

# =========================================================================
# INFRASTRUCTURE SERVICES (VMIDs 300-302)
# =========================================================================

resource "proxmox_virtual_environment_container" "postgres" {
  node_name = "pveserver2"
  vm_id     = 300

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 100
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-postgres-01"

    ip_config {
      ipv4 {
        address = "10.27.27.70/24"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "redis" {
  node_name = "pves3"
  vm_id     = 301

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-redis-01"

    ip_config {
      ipv4 {
        address = "10.27.27.71/24"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "minio" {
  node_name = "pveserver4"
  vm_id     = 302

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 50
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-minio-01"

    ip_config {
      ipv4 {
        address = "10.27.27.72/24"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

# =========================================================================
# CORE SERVICES (VMIDs 310-327)
# =========================================================================

resource "proxmox_virtual_environment_container" "auth" {
  node_name = "pveserver2"
  vm_id     = 310

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-auth-01"

    ip_config {
      ipv4 {
        address = "10.27.27.80/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "users" {
  node_name = "pves3"
  vm_id     = 311

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-users-01"

    ip_config {
      ipv4 {
        address = "10.27.27.81/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "messaging" {
  node_name = "pveserver4"
  vm_id     = 312

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-messaging-01"

    ip_config {
      ipv4 {
        address = "10.27.27.82/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "matches" {
  node_name = "pveserver2"
  vm_id     = 313

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-matches-01"

    ip_config {
      ipv4 {
        address = "10.27.27.83/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "analytics" {
  node_name = "pves3"
  vm_id     = 314

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-analytics-01"

    ip_config {
      ipv4 {
        address = "10.27.27.84/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "video_call" {
  node_name = "pveserver4"
  vm_id     = 315

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-video-call-01"

    ip_config {
      ipv4 {
        address = "10.27.27.85/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "travel" {
  node_name = "pveserver2"
  vm_id     = 316

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-travel-01"

    ip_config {
      ipv4 {
        address = "10.27.27.86/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "moderation" {
  node_name = "pves3"
  vm_id     = 317

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-moderation-01"

    ip_config {
      ipv4 {
        address = "10.27.27.87/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "permission" {
  node_name = "pveserver4"
  vm_id     = 318

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-permission-01"

    ip_config {
      ipv4 {
        address = "10.27.27.88/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "notification" {
  node_name = "pveserver2"
  vm_id     = 319

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-notification-01"

    ip_config {
      ipv4 {
        address = "10.27.27.89/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "payment" {
  node_name = "pves3"
  vm_id     = 320

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-payment-01"

    ip_config {
      ipv4 {
        address = "10.27.27.90/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "admin" {
  node_name = "pveserver4"
  vm_id     = 321

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-admin-01"

    ip_config {
      ipv4 {
        address = "10.27.27.91/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "ai" {
  node_name = "pveserver2"
  vm_id     = 322

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 30
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-ai-01"

    ip_config {
      ipv4 {
        address = "10.27.27.92/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "job_processing" {
  node_name = "pves3"
  vm_id     = 323

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-jobs-01"

    ip_config {
      ipv4 {
        address = "10.27.27.93/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "location" {
  node_name = "pveserver4"
  vm_id     = 324

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-location-01"

    ip_config {
      ipv4 {
        address = "10.27.27.94/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "match_limits" {
  node_name = "pveserver2"
  vm_id     = 325

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-limits-01"

    ip_config {
      ipv4 {
        address = "10.27.27.95/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "file_processing" {
  node_name = "pves3"
  vm_id     = 326

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-files-01"

    ip_config {
      ipv4 {
        address = "10.27.27.96/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

resource "proxmox_virtual_environment_container" "orchestrator" {
  node_name = "pveserver4"
  vm_id     = 327

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 30
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.container_template
    type             = "ubuntu"
  }

  initialization {
    hostname = "btd-orchestrator-01"

    ip_config {
      ipv4 {
        address = "10.27.27.97/23"
        gateway = "10.27.27.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      console,
      features,
      tags,
      started,
      start_on_boot,
      unprivileged
    ]
  }
}

# =========================================================================
# OUTPUTS
# =========================================================================

output "infrastructure_containers" {
  value = {
    postgres = {
      ip   = "10.27.27.70"
      vmid = proxmox_virtual_environment_container.postgres.vm_id
      node = proxmox_virtual_environment_container.postgres.node_name
    }
    redis = {
      ip   = "10.27.27.71"
      vmid = proxmox_virtual_environment_container.redis.vm_id
      node = proxmox_virtual_environment_container.redis.node_name
    }
    minio = {
      ip   = "10.27.27.72"
      vmid = proxmox_virtual_environment_container.minio.vm_id
      node = proxmox_virtual_environment_container.minio.node_name
    }
  }
  description = "Infrastructure container details"
}

output "service_containers" {
  value = {
    auth = {
      ip   = "10.27.27.80"
      vmid = proxmox_virtual_environment_container.auth.vm_id
      node = proxmox_virtual_environment_container.auth.node_name
    }
    users = {
      ip   = "10.27.27.81"
      vmid = proxmox_virtual_environment_container.users.vm_id
      node = proxmox_virtual_environment_container.users.node_name
    }
    messaging = {
      ip   = "10.27.27.82"
      vmid = proxmox_virtual_environment_container.messaging.vm_id
      node = proxmox_virtual_environment_container.messaging.node_name
    }
    matches = {
      ip   = "10.27.27.83"
      vmid = proxmox_virtual_environment_container.matches.vm_id
      node = proxmox_virtual_environment_container.matches.node_name
    }
    analytics = {
      ip   = "10.27.27.84"
      vmid = proxmox_virtual_environment_container.analytics.vm_id
      node = proxmox_virtual_environment_container.analytics.node_name
    }
    video_call = {
      ip   = "10.27.27.85"
      vmid = proxmox_virtual_environment_container.video_call.vm_id
      node = proxmox_virtual_environment_container.video_call.node_name
    }
    travel = {
      ip   = "10.27.27.86"
      vmid = proxmox_virtual_environment_container.travel.vm_id
      node = proxmox_virtual_environment_container.travel.node_name
    }
    moderation = {
      ip   = "10.27.27.87"
      vmid = proxmox_virtual_environment_container.moderation.vm_id
      node = proxmox_virtual_environment_container.moderation.node_name
    }
    permission = {
      ip   = "10.27.27.88"
      vmid = proxmox_virtual_environment_container.permission.vm_id
      node = proxmox_virtual_environment_container.permission.node_name
    }
    notification = {
      ip   = "10.27.27.89"
      vmid = proxmox_virtual_environment_container.notification.vm_id
      node = proxmox_virtual_environment_container.notification.node_name
    }
    payment = {
      ip   = "10.27.27.90"
      vmid = proxmox_virtual_environment_container.payment.vm_id
      node = proxmox_virtual_environment_container.payment.node_name
    }
    admin = {
      ip   = "10.27.27.91"
      vmid = proxmox_virtual_environment_container.admin.vm_id
      node = proxmox_virtual_environment_container.admin.node_name
    }
    ai = {
      ip   = "10.27.27.92"
      vmid = proxmox_virtual_environment_container.ai.vm_id
      node = proxmox_virtual_environment_container.ai.node_name
    }
    job_processing = {
      ip   = "10.27.27.93"
      vmid = proxmox_virtual_environment_container.job_processing.vm_id
      node = proxmox_virtual_environment_container.job_processing.node_name
    }
    location = {
      ip   = "10.27.27.94"
      vmid = proxmox_virtual_environment_container.location.vm_id
      node = proxmox_virtual_environment_container.location.node_name
    }
    match_limits = {
      ip   = "10.27.27.95"
      vmid = proxmox_virtual_environment_container.match_limits.vm_id
      node = proxmox_virtual_environment_container.match_limits.node_name
    }
    file_processing = {
      ip   = "10.27.27.96"
      vmid = proxmox_virtual_environment_container.file_processing.vm_id
      node = proxmox_virtual_environment_container.file_processing.node_name
    }
    orchestrator = {
      ip   = "10.27.27.97"
      vmid = proxmox_virtual_environment_container.orchestrator.vm_id
      node = proxmox_virtual_environment_container.orchestrator.node_name
    }
  }
  description = "Service container details"
}

output "container_summary" {
  value = {
    total_containers = 21
    nodes = {
      pveserver2 = 7
      pves3      = 7
      pveserver4 = 7
    }
    storage_type = "local-lvm"
  }
  description = "Summary of imported containers"
}