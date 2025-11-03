# Variables for Infrastructure Module

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "base_vm_id" {
  description = "Base VM ID for infrastructure containers"
  type        = number
  default     = 200
}

variable "base_ip_prefix" {
  description = "Base IP prefix for infrastructure containers (e.g., 10.0.1)"
  type        = string
  default     = "10.0.1"
}

variable "template" {
  description = "Container template"
  type        = string
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "debian"
}

variable "cpu_cores" {
  description = "Number of CPU cores for infrastructure containers"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB for infrastructure containers"
  type        = number
  default     = 2048
}

variable "swap" {
  description = "Swap in MB for infrastructure containers"
  type        = number
  default     = 512
}

variable "disk_storage" {
  description = "Storage for root disk"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size for infrastructure containers"
  type        = string
  default     = "20G"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start on boot"
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "SSH public keys"
  type        = list(string)
  default     = []
}