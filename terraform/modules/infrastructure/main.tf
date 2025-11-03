# Infrastructure Module for BTD Application
# Creates infrastructure containers (Redis, PostgreSQL, Consul, MinIO, etc.)

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}

# Local variables for infrastructure containers
locals {
  infrastructure_containers = {
    redis = {
      vm_id       = var.base_vm_id
      description = "Redis - In-memory data store and cache"
      ip_address  = "${var.base_ip_prefix}.10/24"
      tags        = ["infrastructure", "redis", "cache"]
      startup     = 1
    }
    postgres = {
      vm_id       = var.base_vm_id + 1
      description = "PostgreSQL - Primary database server"
      ip_address  = "${var.base_ip_prefix}.11/24"
      tags        = ["infrastructure", "postgres", "database"]
      startup     = 2
    }
    consul = {
      vm_id       = var.base_vm_id + 2
      description = "Consul - Service discovery and configuration"
      ip_address  = "${var.base_ip_prefix}.12/24"
      tags        = ["infrastructure", "consul", "service-discovery"]
      startup     = 1
    }
    minio = {
      vm_id       = var.base_vm_id + 3
      description = "MinIO - Object storage server"
      ip_address  = "${var.base_ip_prefix}.13/24"
      tags        = ["infrastructure", "minio", "storage"]
      startup     = 3
    }
    rabbitmq = {
      vm_id       = var.base_vm_id + 4
      description = "RabbitMQ - Message broker"
      ip_address  = "${var.base_ip_prefix}.14/24"
      tags        = ["infrastructure", "rabbitmq", "messaging"]
      startup     = 3
    }
    monitoring = {
      vm_id       = var.base_vm_id + 5
      description = "Monitoring - Prometheus and Grafana"
      ip_address  = "${var.base_ip_prefix}.15/24"
      tags        = ["infrastructure", "monitoring", "observability"]
      startup     = 4
    }
  }
}

# Create infrastructure containers
module "infrastructure_containers" {
  source = "../lxc-container"

  for_each = local.infrastructure_containers

  node_name   = var.node_name
  vm_id       = each.value.vm_id
  description = each.value.description
  tags        = each.value.tags

  template = var.template
  os_type  = var.os_type

  cpu_cores = var.cpu_cores
  memory    = var.memory
  swap      = var.swap

  disk_storage = var.disk_storage
  disk_size    = var.disk_size

  network_bridge = var.network_bridge
  ip_address     = each.value.ip_address
  gateway        = var.gateway
  dns_servers    = var.dns_servers

  startup_order  = each.value.startup
  startup_delay  = 5
  shutdown_delay = 5

  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot
  ssh_keys      = var.ssh_keys
}