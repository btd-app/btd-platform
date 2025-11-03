# LXC Container Module for BTD Application
# Creates a standardized LXC container on Proxmox

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}

# LXC Container Resource
resource "proxmox_virtual_environment_container" "container" {
  node_name = var.node_name
  vm_id     = var.vm_id

  description = var.description
  tags        = var.tags

  # Operating System and Template
  operating_system {
    template_file_id = var.template
    type             = var.os_type
  }

  # CPU Configuration
  cpu {
    cores = var.cpu_cores
  }

  # Memory Configuration
  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  # Root Disk Configuration
  disk {
    datastore_id = var.disk_storage
    size         = parseint(trimspace(replace(var.disk_size, "G", "")), 10)
  }

  # Network Configuration
  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  # Initialization Configuration
  initialization {
    hostname = var.description

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys = var.ssh_keys
    }
  }

  # Startup Configuration
  startup {
    order      = var.startup_order
    up_delay   = var.startup_delay
    down_delay = var.shutdown_delay
  }

  # Container Features
  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot

  # Lifecycle Configuration
  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
    ]
  }
}