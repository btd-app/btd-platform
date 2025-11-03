# Outputs for LXC Container Module

output "container_id" {
  description = "Container VM ID"
  value       = proxmox_virtual_environment_container.container.vm_id
}

output "container_name" {
  description = "Container hostname"
  value       = proxmox_virtual_environment_container.container.node_name
}

output "ip_address" {
  description = "Container IP address"
  value       = var.ip_address
}

output "mac_address" {
  description = "Container MAC address"
  value       = try(proxmox_virtual_environment_container.container.network_interface[0].mac_address, "")
}