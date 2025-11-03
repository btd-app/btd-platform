# BTD Application Terraform Configuration
# This file contains the ACTUAL values from the existing infrastructure
# Updated to match the real LXC containers as deployed in Proxmox

# Proxmox Configuration - Real cluster nodes
proxmox_api_endpoint = "https://10.27.27.192:8006/api2/json"
proxmox_api_token    = "root@pam!terraform=2bca6d8d-b500-43e6-a7f8-400e7132da9f"  # TODO: Move to environment variable for production
proxmox_api_user     = "terraform@pam"
proxmox_api_insecure = true
proxmox_ssh_user     = "root"

# Proxmox Cluster Nodes (actual node names)
proxmox_nodes = {
  pveserver2 = {
    name = "pveserver2"
    ip   = "10.27.27.192"
  }
  pves3 = {
    name = "pves3"
    ip   = "10.27.27.193"
  }
  pveserver4 = {
    name = "pveserver4"
    ip   = "10.27.27.194"
  }
}

# Network Configuration - Actual production network
network_bridge  = "vmbr0"
network_subnet  = "10.27.27.0/24"
network_gateway = "10.27.27.1"
network_dns     = ["10.27.27.27", "10.27.27.115"]
network_search_domain = "btd.internal service.consul"

# Container Template - Actual template used
container_template = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"

# Storage Pools (Ceph RBD - actual pools from Proxmox)
# Using SSDs for best performance on databases/cache/services
# Using sixteen_tb_hdds for large object storage (MinIO)
ceph_storage_databases = "ssds"              # Fast storage for PostgreSQL
ceph_storage_cache     = "ssds"              # Fast storage for Redis
ceph_storage_services  = "ssds"              # Fast storage for services
ceph_storage_objects   = "sixteen_tb_hdds"   # Large capacity for MinIO object storage

# Infrastructure Container Resources (matches actual deployment)
infrastructure_container_specs = {
  postgres = {
    cores  = 4
    memory = 8192
    swap   = 512
    disk   = "100G"
  }
  redis = {
    cores  = 2
    memory = 4096
    swap   = 512
    disk   = "50G"
  }
  minio = {
    cores  = 2
    memory = 4096
    swap   = 512
    disk   = "500G"
  }
  verdaccio = {
    cores  = 2
    memory = 2048
    swap   = 512
    disk   = "50G"
  }
  haproxy = {
    cores  = 2
    memory = 2048
    swap   = 512
    disk   = "10G"
  }
  monitoring = {
    cores  = 2
    memory = 4096
    swap   = 512
    disk   = "100G"
  }
}

# Gateway Container Resources
gateway_container_specs = {
  cores  = 4
  memory = 4096
  swap   = 512
  disk   = "15G"
}

# Service Container Resources (default)
service_container_specs = {
  cores  = 2
  memory = 2048
  swap   = 512
  disk   = "10G"
}

# Service-specific overrides
service_overrides = {
  messaging = {
    memory = 3072
    disk   = "15G"
  }
  matches = {
    cores  = 3
    memory = 4096
    disk   = "20G"
  }
  analytics = {
    memory = 3072
    disk   = "20G"
  }
  ai = {
    cores  = 3
    memory = 4096
    disk   = "15G"
  }
  video_call = {
    memory = 3072
    disk   = "15G"
  }
  file_processing = {
    memory = 3072
    disk   = "20G"
  }
  location = {
    disk = "15G"
  }
}

# Container Configuration
start_on_boot = true
unprivileged  = true

# LXC Features
lxc_features = {
  nesting = 1
  keyctl  = 1
  fuse    = 1
}

# Container Base IDs (actual values from inventory)
infrastructure_base_id = 300
gateway_base_id        = 310
core_services_base_id  = 311
business_base_id       = 317
support_base_id        = 324

# Environment
environment = "production"

# Consul Configuration
consul_address    = "10.27.27.27:8500"
consul_datacenter = "dc1"
consul_servers    = ["10.27.27.27", "10.27.27.115", "10.27.27.116"]

# Tags
common_tags = {
  Project     = "BTD"
  ManagedBy   = "Terraform"
  Environment = "production"
  CreatedBy   = "terraform-expert"
}

# SSH Public Keys (to be populated from environment or vault)
ssh_public_keys = []