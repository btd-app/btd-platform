# Variables for LXC Container Module

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_id" {
  description = "Container ID"
  type        = number
}

variable "description" {
  description = "Container description"
  type        = string
}

variable "tags" {
  description = "Container tags"
  type        = list(string)
  default     = []
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
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 1024
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 256
}

variable "disk_storage" {
  description = "Storage for root disk"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size (e.g., 10G)"
  type        = string
  default     = "10G"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "IP address with CIDR"
  type        = string
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

variable "startup_order" {
  description = "Startup order"
  type        = number
  default     = 1
}

variable "startup_delay" {
  description = "Startup delay in seconds"
  type        = number
  default     = 0
}

variable "shutdown_delay" {
  description = "Shutdown delay in seconds"
  type        = number
  default     = 0
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