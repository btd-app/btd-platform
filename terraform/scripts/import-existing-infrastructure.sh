#!/bin/bash
# Import existing LXC containers into Terraform state
# This script imports all 21 existing containers from Proxmox
# Updated with correct VMIDs and node assignments from actual infrastructure

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$SCRIPT_DIR/.."

# Dry run mode flag
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}Running in DRY-RUN mode. No changes will be made.${NC}"
fi

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Track results
declare -i TOTAL=0
declare -i SUCCESS=0
declare -i FAILED=0

# Function to import a container
import_container() {
    local resource_name=$1
    local node=$2
    local vmid=$3
    local description=$4

    echo -e "${GREEN}Importing:${NC} $description (VMID: $vmid on $node)"

    TOTAL=$((TOTAL + 1))

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would execute: terraform import proxmox_virtual_environment_container.$resource_name $node/$vmid"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "  Executing: terraform import proxmox_virtual_environment_container.$resource_name $node/$vmid"
        if terraform import proxmox_virtual_environment_container.$resource_name $node/$vmid; then
            echo -e "  ${GREEN}✓${NC} Successfully imported $resource_name"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "  ${RED}✗${NC} Failed to import $resource_name"
            FAILED=$((FAILED + 1))
        fi
    fi
    echo ""
}

# Initialize Terraform if needed
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    if ! terraform init; then
        echo -e "${RED}Failed to initialize Terraform. Please check your configuration.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Starting import of existing LXC containers...${NC}"
echo "=========================================="
echo ""

# =========================================================================
# INFRASTRUCTURE SERVICES (VMIDs 300-302)
# =========================================================================

echo -e "${YELLOW}Importing Infrastructure Services...${NC}"

# PostgreSQL - VMID 300 on pveserver2
import_container "postgres" "pveserver2" "300" "PostgreSQL Primary Database (10.27.27.70)"

# Redis - VMID 301 on pves3
import_container "redis" "pves3" "301" "Redis Primary Cache (10.27.27.71)"

# MinIO - VMID 302 on pveserver4
import_container "minio" "pveserver4" "302" "MinIO Object Storage (10.27.27.72)"

# =========================================================================
# CORE SERVICES (VMIDs 310-327)
# =========================================================================

echo -e "${YELLOW}Importing Core and Application Services...${NC}"

# Auth Service - VMID 310 on pveserver2
import_container "auth" "pveserver2" "310" "Authentication Service (10.27.27.80)"

# Users Service - VMID 311 on pves3
import_container "users" "pves3" "311" "Users Service (10.27.27.81)"

# Messaging Service - VMID 312 on pveserver4
import_container "messaging" "pveserver4" "312" "Messaging Service (10.27.27.82)"

# Matches Service - VMID 313 on pveserver2
import_container "matches" "pveserver2" "313" "Matches Service (10.27.27.83)"

# Analytics Service - VMID 314 on pves3
import_container "analytics" "pves3" "314" "Analytics Service (10.27.27.84)"

# Video Call Service - VMID 315 on pveserver4
import_container "video_call" "pveserver4" "315" "Video Call Service (10.27.27.85)"

# Travel Service - VMID 316 on pveserver2
import_container "travel" "pveserver2" "316" "Travel Service (10.27.27.86)"

# Moderation Service - VMID 317 on pves3
import_container "moderation" "pves3" "317" "Moderation Service (10.27.27.87)"

# Permission Service - VMID 318 on pveserver4
import_container "permission" "pveserver4" "318" "Permission Service (10.27.27.88)"

# Notification Service - VMID 319 on pveserver2
import_container "notification" "pveserver2" "319" "Notification Service (10.27.27.89)"

# Payment Service - VMID 320 on pves3
import_container "payment" "pves3" "320" "Payment Service (10.27.27.90)"

# Admin Service - VMID 321 on pveserver4
import_container "admin" "pveserver4" "321" "Admin Service (10.27.27.91)"

# AI Service - VMID 322 on pveserver2
import_container "ai" "pveserver2" "322" "AI Service (10.27.27.92)"

# Job Processing Service - VMID 323 on pves3
import_container "job_processing" "pves3" "323" "Job Processing Service (10.27.27.93)"

# Location Service - VMID 324 on pveserver4
import_container "location" "pveserver4" "324" "Location Service (10.27.27.94)"

# Match Limits Service - VMID 325 on pveserver2
import_container "match_limits" "pveserver2" "325" "Match Request Limits Service (10.27.27.95)"

# File Processing Service - VMID 326 on pves3
import_container "file_processing" "pves3" "326" "File Processing Service (10.27.27.96)"

# Orchestrator - VMID 327 on pveserver4
import_container "orchestrator" "pveserver4" "327" "Orchestrator API Gateway (10.27.27.97)"

# =========================================================================
# SUMMARY
# =========================================================================

echo ""
echo "=========================================="
echo -e "${GREEN}Import Summary:${NC}"
echo "Total containers: $TOTAL"
echo -e "Successfully imported: ${GREEN}$SUCCESS${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "Failed imports: ${RED}$FAILED${NC}"
else
    echo -e "Failed imports: ${GREEN}$FAILED${NC}"
fi

if [ "$DRY_RUN" = false ] && [ $SUCCESS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Verifying import...${NC}"
    echo "Running 'terraform state list' to show imported resources:"
    terraform state list | grep proxmox_virtual_environment_container || true

    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Run 'terraform plan' to verify the imported state matches configuration"
    echo "2. If there are any differences, review and adjust the configuration"
    echo "3. Once 'terraform plan' shows no changes, your import is complete"
    echo ""
    echo -e "${GREEN}Note:${NC} The containers are currently using local-lvm storage."
    echo "To migrate to Ceph storage in the future, see CEPH-MIGRATION-PLAN.md"
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}This was a dry run. To actually import, run without --dry-run flag.${NC}"
    echo -e "${GREEN}Command to execute actual import:${NC}"
    echo "  ./scripts/import-existing-infrastructure.sh"
fi

# Show container distribution across nodes
echo ""
echo "=========================================="
echo -e "${GREEN}Container Distribution:${NC}"
echo "pveserver2: 7 containers"
echo "pves3:      7 containers"
echo "pveserver4: 7 containers"
echo "Total:      21 containers"

exit 0