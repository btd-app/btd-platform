#!/usr/bin/env python3

"""
BTD Platform - Generate Ansible Inventory from Terraform Outputs

Purpose: Convert Terraform JSON outputs to Ansible inventory format
Usage: python3 generate-ansible-inventory.py <terraform_output.json> <inventory_output.yml>

Network: 10.27.27.0/23
"""

import json
import sys
import yaml
from pathlib import Path

def load_terraform_outputs(terraform_file):
    """Load Terraform outputs from JSON file"""
    try:
        with open(terraform_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading Terraform outputs: {e}", file=sys.stderr)
        sys.exit(1)

def generate_inventory(terraform_outputs):
    """Generate Ansible inventory structure from Terraform outputs"""

    inventory = {
        'all': {
            'children': {
                'infrastructure': {
                    'hosts': {},
                    'vars': {
                        'ansible_user': 'root',
                        'ansible_python_interpreter': '/usr/bin/python3'
                    }
                },
                'services': {
                    'hosts': {},
                    'vars': {
                        'ansible_user': 'root',
                        'ansible_python_interpreter': '/usr/bin/python3',
                        'btd_app_root': '/opt/btd-app'
                    }
                }
            },
            'vars': {
                'ansible_ssh_private_key_file': '~/.ssh/ansible_rsa',
                'ansible_ssh_common_args': '-o StrictHostKeyChecking=no'
            }
        }
    }

    # Parse infrastructure containers
    infra_containers = terraform_outputs.get('infrastructure_containers', {}).get('value', {})
    for name, details in infra_containers.items():
        ip_address = details.get('ip_address', '')
        inventory['all']['children']['infrastructure']['hosts'][name] = {
            'ansible_host': ip_address,
            'container_id': details.get('container_id', ''),
            'vmid': details.get('vmid', ''),
            'node': details.get('node', 'pve')
        }

    # Parse service containers
    service_containers = terraform_outputs.get('service_containers', {}).get('value', {})
    for name, details in service_containers.items():
        ip_address = details.get('ip_address', '')
        inventory['all']['children']['services']['hosts'][name] = {
            'ansible_host': ip_address,
            'container_id': details.get('container_id', ''),
            'vmid': details.get('vmid', ''),
            'node': details.get('node', 'pve'),
            'service_name': details.get('service_name', name),
            'service_port': details.get('service_port', 3000),
            'grpc_port': details.get('grpc_port', 50051)
        }

    # Create service-specific groups
    service_groups = {
        'orchestrator_servers': [],
        'auth_servers': [],
        'user_servers': [],
        'messaging_servers': [],
        'database_servers': [],
        'cache_servers': [],
        'storage_servers': []
    }

    # Categorize hosts
    for hostname in inventory['all']['children']['infrastructure']['hosts'].keys():
        if 'postgres' in hostname.lower():
            service_groups['database_servers'].append(hostname)
        elif 'redis' in hostname.lower():
            service_groups['cache_servers'].append(hostname)
        elif 'minio' in hostname.lower():
            service_groups['storage_servers'].append(hostname)

    for hostname in inventory['all']['children']['services']['hosts'].keys():
        if 'orchestrator' in hostname.lower():
            service_groups['orchestrator_servers'].append(hostname)
        elif 'auth' in hostname.lower():
            service_groups['auth_servers'].append(hostname)
        elif 'user' in hostname.lower():
            service_groups['user_servers'].append(hostname)
        elif 'messaging' in hostname.lower():
            service_groups['messaging_servers'].append(hostname)

    # Add service groups to inventory
    for group_name, hosts in service_groups.items():
        if hosts:
            inventory['all']['children'][group_name] = {
                'hosts': {host: {} for host in hosts}
            }

    return inventory

def write_inventory(inventory, output_file):
    """Write inventory to YAML file"""
    try:
        # Ensure output directory exists
        Path(output_file).parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w') as f:
            yaml.dump(inventory, f, default_flow_style=False, sort_keys=False)

        print(f"✓ Ansible inventory generated: {output_file}")
    except Exception as e:
        print(f"Error writing inventory file: {e}", file=sys.stderr)
        sys.exit(1)

def print_summary(inventory):
    """Print inventory summary"""
    infra_count = len(inventory['all']['children']['infrastructure']['hosts'])
    service_count = len(inventory['all']['children']['services']['hosts'])

    print("\n========================================")
    print("Inventory Summary")
    print("========================================")
    print(f"Infrastructure hosts: {infra_count}")
    print(f"Service hosts: {service_count}")
    print(f"Total hosts: {infra_count + service_count}")
    print("========================================\n")

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 generate-ansible-inventory.py <terraform_output.json> <inventory_output.yml>")
        sys.exit(1)

    terraform_file = sys.argv[1]
    inventory_file = sys.argv[2]

    print(f"Loading Terraform outputs from: {terraform_file}")
    terraform_outputs = load_terraform_outputs(terraform_file)

    print("Generating Ansible inventory...")
    inventory = generate_inventory(terraform_outputs)

    print_summary(inventory)

    write_inventory(inventory, inventory_file)

    print("✓ Inventory generation complete")

if __name__ == '__main__':
    main()
