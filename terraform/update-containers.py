#!/usr/bin/env python3
"""
Update all container configurations to match imported state and prevent recreation.
"""
import re

def process_container_block(container_text):
    """Process a single container resource block to update configuration."""

    # Extract container name for reference
    name_match = re.search(r'resource "proxmox_virtual_environment_container" "(\w+)"', container_text)
    if not name_match:
        return container_text

    container_name = name_match.group(1)

    # Comment out or remove problematic attributes
    modifications = [
        # Comment out description to avoid changes
        (r'(\s+)(description\s*=.*)', r'\1# \2  # Commented to avoid changes'),

        # Update tags to just "btd"
        (r'(\s+)tags\s*=\s*\[.*?\]', r'\1tags        = ["btd"]  # Using existing tag to match current state'),

        # Comment out unprivileged
        (r'(\s+)(unprivileged\s*=.*)', r'\1# \2  # Removed to prevent recreation'),

        # Comment out start_on_boot
        (r'(\s+)(start_on_boot\s*=.*)', r'\1# \2  # Removed to prevent changes'),

        # Simplify hostname - remove .btd.internal suffix
        (r'(\s+hostname\s*=\s*"[^"]+)\.btd\.internal"', r'\1"  # Simplified to match current state'),
    ]

    result = container_text
    for pattern, replacement in modifications:
        result = re.sub(pattern, replacement, result, flags=re.MULTILINE)

    # Comment out entire blocks
    blocks_to_comment = [
        # DNS block
        (r'(\s+)(dns\s*\{[^}]*\})', r'\1# dns {\n\1#   servers = var.network_dns\n\1# }'),

        # User account block
        (r'(\s+)(user_account\s*\{[^}]*\})', r'\1# user_account {  # Removed to prevent recreation\n\1#   keys = var.ssh_public_keys\n\1# }'),

        # Startup block
        (r'(\s+)(startup\s*\{[^}]*?\n\s*\})', lambda m: '\n'.join('  # ' + line if line.strip() else '' for line in m.group(0).split('\n'))),
    ]

    for pattern, replacement in blocks_to_comment:
        result = re.sub(pattern, replacement, result, flags=re.MULTILINE | re.DOTALL)

    # Add lifecycle block if not present
    if 'lifecycle {' not in result:
        lifecycle_block = """
  lifecycle {
    ignore_changes = [
      description,
      operating_system[0].template_file_id,
      initialization[0].user_account,
      initialization[0].dns,
      startup,
      start_on_boot,
      unprivileged
    ]
  }"""
        # Insert before the closing brace
        last_brace = result.rfind('}')
        result = result[:last_brace] + lifecycle_block + '\n' + result[last_brace:]

    return result

def main():
    # Read the main.tf file
    with open('/root/projects/btd-app/terraform/main.tf', 'r') as f:
        content = f.read()

    # Split into container resource blocks
    # Match resource blocks from 'resource "proxmox' to the closing brace
    pattern = r'(resource "proxmox_virtual_environment_container"[^{]*\{(?:[^{}]|\{[^}]*\})*\})'

    def replacer(match):
        return process_container_block(match.group(0))

    # Process all container blocks
    updated_content = re.sub(pattern, replacer, content, flags=re.MULTILINE | re.DOTALL)

    # Write the updated content
    with open('/root/projects/btd-app/terraform/main.tf.updated', 'w') as f:
        f.write(updated_content)

    print("Updated configuration written to main.tf.updated")
    print("Review the changes and then run: mv main.tf.updated main.tf")

if __name__ == '__main__':
    main()