terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.21.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_api_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}

provider "consul" {
  address    = var.consul_address
  datacenter = var.consul_datacenter
  token      = var.consul_token
}