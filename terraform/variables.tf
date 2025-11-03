# BTD Application Infrastructure Variables
# This file defines the input variables for the BTD infrastructure

# =========================================================================
# PROXMOX CONFIGURATION
# =========================================================================

variable "proxmox_api_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_api_user" {
  description = "Proxmox API username"
  type        = string
  default     = "terraform@pam"
}

variable "proxmox_api_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_api_token" {
  description = "Proxmox API token (alternative to password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_api_insecure" {
  description = "Allow insecure TLS connection to Proxmox"
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "SSH user for Proxmox nodes"
  type        = string
  default     = "root"
}

variable "proxmox_nodes" {
  description = "Map of Proxmox cluster nodes"
  type = map(object({
    name = string
    ip   = string
  }))
}

# =========================================================================
# NETWORK CONFIGURATION
# =========================================================================

variable "network_bridge" {
  description = "Network bridge to use for containers"
  type        = string
  default     = "vmbr0"
}

variable "network_subnet" {
  description = "Network subnet in CIDR format"
  type        = string
}

variable "network_gateway" {
  description = "Network gateway IP address"
  type        = string
}

variable "network_dns" {
  description = "DNS servers for containers"
  type        = list(string)
}

variable "network_search_domain" {
  description = "DNS search domain"
  type        = string
  default     = "btd.internal service.consul"
}

# =========================================================================
# STORAGE CONFIGURATION
# =========================================================================

variable "ceph_storage_databases" {
  description = "Ceph storage pool for databases"
  type        = string
}

variable "ceph_storage_cache" {
  description = "Ceph storage pool for cache"
  type        = string
}

variable "ceph_storage_services" {
  description = "Ceph storage pool for services"
  type        = string
}

variable "ceph_storage_objects" {
  description = "Ceph storage pool for object storage"
  type        = string
}

# =========================================================================
# CONTAINER CONFIGURATION
# =========================================================================

variable "container_template" {
  description = "LXC container template to use"
  type        = string
}

variable "start_on_boot" {
  description = "Start containers on boot"
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Run containers as unprivileged"
  type        = bool
  default     = true
}

variable "lxc_features" {
  description = "LXC container features"
  type = object({
    nesting = number
    keyctl  = number
    fuse    = number
  })
  default = {
    nesting = 1
    keyctl  = 1
    fuse    = 1
  }
}

# =========================================================================
# RESOURCE SPECIFICATIONS
# =========================================================================

variable "infrastructure_container_specs" {
  description = "Resource specifications for infrastructure containers"
  type = map(object({
    cores  = number
    memory = number
    swap   = number
    disk   = string
  }))
}

variable "gateway_container_specs" {
  description = "Resource specifications for the gateway container"
  type = object({
    cores  = number
    memory = number
    swap   = number
    disk   = string
  })
}

variable "service_container_specs" {
  description = "Default resource specifications for service containers"
  type = object({
    cores  = number
    memory = number
    swap   = number
    disk   = string
  })
}

variable "service_overrides" {
  description = "Service-specific resource overrides"
  type = map(object({
    cores  = optional(number)
    memory = optional(number)
    swap   = optional(number)
    disk   = optional(string)
  }))
  default = {}
}

# =========================================================================
# CONTAINER BASE IDS
# =========================================================================

variable "infrastructure_base_id" {
  description = "Base VM ID for infrastructure containers"
  type        = number
}

variable "gateway_base_id" {
  description = "Base VM ID for gateway container"
  type        = number
}

variable "core_services_base_id" {
  description = "Base VM ID for core service containers"
  type        = number
}

variable "business_base_id" {
  description = "Base VM ID for business service containers"
  type        = number
}

variable "support_base_id" {
  description = "Base VM ID for support service containers"
  type        = number
}

# =========================================================================
# CONSUL CONFIGURATION
# =========================================================================

variable "consul_address" {
  description = "Consul server address"
  type        = string
}

variable "consul_datacenter" {
  description = "Consul datacenter name"
  type        = string
  default     = "dc1"
}

variable "consul_servers" {
  description = "List of Consul server IPs"
  type        = list(string)
}

variable "consul_token" {
  description = "Consul ACL token for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

# =========================================================================
# ENVIRONMENT AND TAGS
# =========================================================================

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# SSH CONFIGURATION
# =========================================================================

variable "ssh_public_keys" {
  description = "SSH public keys for container access"
  type        = list(string)
  default     = []
}