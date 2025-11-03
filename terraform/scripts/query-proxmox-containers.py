#!/usr/bin/env python3
"""
Query Proxmox API to get exact configuration of existing LXC containers.
This will help us update Terraform configuration to match reality.
"""

import json
import urllib3
import requests
from typing import Dict, List, Any

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Proxmox configuration
PROXMOX_HOST = "10.27.27.192"
PROXMOX_PORT = 8006
PROXMOX_TOKEN = "root@pam!terraform=2bca6d8d-b500-43e6-a7f8-400e7132da9f"

# Headers for API requests
headers = {
    "Authorization": f"PVEAPIToken={PROXMOX_TOKEN}",
    "Content-Type": "application/json"
}

# Base URL
base_url = f"https://{PROXMOX_HOST}:{PROXMOX_PORT}/api2/json"

def get_cluster_nodes() -> List[str]:
    """Get list of cluster nodes."""
    response = requests.get(f"{base_url}/nodes", headers=headers, verify=False)
    response.raise_for_status()
    return [node['node'] for node in response.json()['data']]

def get_container_config(node: str, vmid: int) -> Dict[str, Any]:
    """Get detailed configuration for a specific container."""
    response = requests.get(f"{base_url}/nodes/{node}/lxc/{vmid}/config",
                           headers=headers, verify=False)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()['data']

def get_container_status(node: str, vmid: int) -> Dict[str, Any]:
    """Get status information for a specific container."""
    response = requests.get(f"{base_url}/nodes/{node}/lxc/{vmid}/status/current",
                           headers=headers, verify=False)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()['data']

def parse_network_config(config: Dict[str, Any]) -> Dict[str, str]:
    """Parse network configuration from container config."""
    net_config = {}
    if 'net0' in config:
        net0 = config['net0']
        parts = net0.split(',')
        for part in parts:
            if '=' in part:
                key, value = part.split('=', 1)
                net_config[key] = value
    return net_config

def parse_rootfs(rootfs: str) -> Dict[str, str]:
    """Parse rootfs configuration to extract storage and size."""
    parts = rootfs.split(',')
    result = {}
    for part in parts:
        if ':' in part and '=' not in part:
            # This is the storage:volume part
            storage, volume = part.split(':', 1)
            result['storage'] = storage
            result['volume'] = volume
        elif '=' in part:
            key, value = part.split('=', 1)
            result[key] = value
    return result

def main():
    # Expected containers based on user's list
    expected_containers = [
        (300, "btd-postgres-01", "pveserver2"),
        (301, "btd-redis-01", "pves3"),
        (302, "btd-minio-01", "pveserver4"),
        (310, "btd-auth-01", "pveserver2"),
        (311, "btd-users-01", "pves3"),
        (312, "btd-messaging-01", "pveserver4"),
        (313, "btd-matches-01", "pveserver2"),
        (314, "btd-analytics-01", "pves3"),
        (315, "btd-video-call-01", "pveserver4"),
        (316, "btd-travel-01", "pveserver2"),
        (317, "btd-moderation-01", "pves3"),
        (318, "btd-permission-01", "pveserver4"),
        (319, "btd-notification-01", "pveserver2"),
        (320, "btd-payment-01", "pves3"),
        (321, "btd-admin-01", "pveserver4"),
        (322, "btd-ai-01", "pveserver2"),
        (323, "btd-jobs-01", "pves3"),
        (324, "btd-location-01", "pveserver4"),
        (325, "btd-limits-01", "pveserver2"),
        (326, "btd-files-01", "pves3"),
        (327, "btd-orchestrator-01", "pveserver4"),
    ]

    print("Querying Proxmox API for container configurations...")
    print("=" * 80)

    containers_found = []
    terraform_config = []

    for vmid, expected_name, expected_node in expected_containers:
        print(f"\nChecking VMID {vmid} ({expected_name})...")

        # Try to find on expected node first
        config = get_container_config(expected_node, vmid)
        status = get_container_status(expected_node, vmid) if config else None
        found_node = expected_node if config else None

        # If not found on expected node, check other nodes
        if not config:
            nodes = get_cluster_nodes()
            for node in nodes:
                if node != expected_node:
                    config = get_container_config(node, vmid)
                    if config:
                        status = get_container_status(node, vmid)
                        found_node = node
                        print(f"  Warning: Found on {node} instead of {expected_node}")
                        break

        if config:
            hostname = config.get('hostname', 'unknown')
            cores = config.get('cores', 1)
            memory = config.get('memory', 1024)
            swap = config.get('swap', 0)

            # Parse rootfs for storage and size
            rootfs_info = parse_rootfs(config.get('rootfs', ''))
            storage = rootfs_info.get('storage', 'unknown')
            size_str = rootfs_info.get('size', '0G')
            # Convert size to integer (GB)
            if size_str.endswith('G'):
                size = int(size_str[:-1])
            else:
                size = 0

            # Parse network configuration
            net_config = parse_network_config(config)
            bridge = net_config.get('bridge', 'vmbr0')
            ip = net_config.get('ip', 'dhcp')

            # Status information
            state = status.get('status', 'unknown') if status else 'unknown'

            print(f"  ✓ Found: {hostname}")
            print(f"    Node: {found_node}")
            print(f"    Status: {state}")
            print(f"    Resources: {cores} cores, {memory}MB RAM, {swap}MB swap")
            print(f"    Storage: {storage}, {size}GB")
            print(f"    Network: {bridge}, IP={ip}")

            containers_found.append({
                'vmid': vmid,
                'hostname': hostname,
                'node': found_node,
                'cores': cores,
                'memory': memory,
                'swap': swap,
                'storage': storage,
                'size': size,
                'bridge': bridge,
                'ip': ip,
                'state': state,
                'expected_name': expected_name
            })

            # Prepare Terraform resource name from hostname
            resource_name = hostname.replace('btd-', '').replace('-01', '').replace('-', '_')
            if resource_name == 'jobs':
                resource_name = 'job_processing'
            elif resource_name == 'files':
                resource_name = 'file_processing'
            elif resource_name == 'limits':
                resource_name = 'match_limits'
            elif resource_name == 'video_call':
                resource_name = 'video_call'

            terraform_config.append({
                'resource_name': resource_name,
                'vmid': vmid,
                'node': found_node,
                'hostname': hostname,
                'cores': cores,
                'memory': memory,
                'swap': swap,
                'storage': storage,
                'size': size,
                'ip': ip
            })
        else:
            print(f"  ✗ Not found on any node")

    print("\n" + "=" * 80)
    print(f"Summary: Found {len(containers_found)} of {len(expected_containers)} containers")

    # Save detailed results
    with open('/root/projects/btd-app/terraform/container-inventory.json', 'w') as f:
        json.dump(containers_found, f, indent=2)

    # Generate Terraform configuration updates
    print("\n" + "=" * 80)
    print("Terraform Configuration Updates Required:")
    print("=" * 80)

    # Group by similar configurations for tfvars
    print("\n# Storage Configuration (all using local-lvm):")
    print("# Update terraform.tfvars to use local-lvm instead of Ceph storage")

    print("\n# Container-to-Node Mapping:")
    for item in terraform_config:
        print(f"# {item['resource_name']}: node={item['node']}, vmid={item['vmid']}, ip={item['ip']}")

    # Save Terraform mapping
    with open('/root/projects/btd-app/terraform/terraform-mapping.json', 'w') as f:
        json.dump(terraform_config, f, indent=2)

    print("\nConfiguration files saved:")
    print("  - container-inventory.json: Complete container details")
    print("  - terraform-mapping.json: Terraform resource mapping")

if __name__ == "__main__":
    main()