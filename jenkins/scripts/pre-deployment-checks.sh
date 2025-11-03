#!/bin/bash

##############################################################################
# BTD Platform - Pre-Deployment Validation Script
#
# Purpose: Validate all prerequisites before deployment
# Usage: ./pre-deployment-checks.sh <environment>
#
# Network: 10.27.27.0/23
# Jenkins Server: 10.27.27.251
##############################################################################

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JENKINS_DIR="$(dirname "$SCRIPT_DIR")"
BTD_APP_ROOT="/root/projects/btd-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error counter
ERRORS=0
WARNINGS=0

##############################################################################
# Infrastructure Checks
##############################################################################

check_proxmox_connectivity() {
    log_info "Checking Proxmox API connectivity..."

    local PROXMOX_API="https://10.27.27.192:8006/api2/json"

    if curl -k -s --max-time 5 "$PROXMOX_API" > /dev/null; then
        log_success "Proxmox API accessible at $PROXMOX_API"
    else
        log_error "Cannot reach Proxmox API at $PROXMOX_API"
        ((ERRORS++))
    fi
}

check_consul_connectivity() {
    log_info "Checking Consul connectivity..."

    local CONSUL_ADDR="10.27.27.27:8500"

    if curl -s --max-time 5 "http://$CONSUL_ADDR/v1/status/leader" > /dev/null; then
        log_success "Consul accessible at $CONSUL_ADDR"

        # Check if Consul has a leader
        local LEADER=$(curl -s "http://$CONSUL_ADDR/v1/status/leader")
        if [ -n "$LEADER" ] && [ "$LEADER" != '""' ]; then
            log_success "Consul has a leader: $LEADER"
        else
            log_error "Consul has no leader elected"
            ((ERRORS++))
        fi
    else
        log_error "Cannot reach Consul at $CONSUL_ADDR"
        ((ERRORS++))
    fi
}

check_postgresql() {
    log_info "Checking PostgreSQL connectivity..."

    local POSTGRES_HOST="10.27.27.30"
    local POSTGRES_PORT="5432"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT" 2>/dev/null; then
        log_success "PostgreSQL accessible at $POSTGRES_HOST:$POSTGRES_PORT"
    else
        log_error "Cannot reach PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT"
        ((ERRORS++))
    fi
}

check_redis() {
    log_info "Checking Redis connectivity..."

    local REDIS_HOST="10.27.27.26"
    local REDIS_PORT="6379"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$REDIS_HOST/$REDIS_PORT" 2>/dev/null; then
        log_success "Redis accessible at $REDIS_HOST:$REDIS_PORT"
    else
        log_error "Cannot reach Redis at $REDIS_HOST:$REDIS_PORT"
        ((ERRORS++))
    fi
}

check_minio() {
    log_info "Checking MinIO connectivity..."

    local MINIO_API="http://10.27.27.28:9000"

    if curl -s --max-time 5 "$MINIO_API/minio/health/live" > /dev/null; then
        log_success "MinIO accessible at $MINIO_API"
    else
        log_error "Cannot reach MinIO at $MINIO_API"
        ((ERRORS++))
    fi
}

##############################################################################
# Terraform Checks
##############################################################################

check_terraform_installation() {
    log_info "Checking Terraform installation..."

    if command -v terraform &> /dev/null; then
        local VERSION=$(terraform version -json | jq -r '.terraform_version')
        log_success "Terraform installed: version $VERSION"
    else
        log_error "Terraform is not installed"
        ((ERRORS++))
    fi
}

check_terraform_state() {
    log_info "Checking Terraform state accessibility..."

    cd "$BTD_APP_ROOT/terraform"

    if terraform init -backend=true &> /dev/null; then
        log_success "Terraform state accessible"

        # Check for state lock
        if terraform state list &> /dev/null; then
            log_success "Terraform state is not locked"
        else
            log_error "Terraform state appears to be locked or corrupted"
            ((ERRORS++))
        fi
    else
        log_error "Cannot initialize Terraform backend"
        ((ERRORS++))
    fi
}

##############################################################################
# Ansible Checks
##############################################################################

check_ansible_installation() {
    log_info "Checking Ansible installation..."

    if command -v ansible &> /dev/null; then
        local VERSION=$(ansible --version | head -n1)
        log_success "Ansible installed: $VERSION"
    else
        log_error "Ansible is not installed"
        ((ERRORS++))
    fi
}

check_ansible_inventory() {
    log_info "Checking Ansible inventory..."

    local INVENTORY_FILE="$BTD_APP_ROOT/btd-ansible/inventories/$ENVIRONMENT/hosts.yml"

    if [ -f "$INVENTORY_FILE" ]; then
        log_success "Ansible inventory exists: $INVENTORY_FILE"

        # Validate inventory syntax
        if ansible-inventory -i "$INVENTORY_FILE" --list &> /dev/null; then
            log_success "Ansible inventory is valid"
        else
            log_error "Ansible inventory has syntax errors"
            ((ERRORS++))
        fi
    else
        log_warning "Ansible inventory not found: $INVENTORY_FILE"
        log_info "Will be generated from Terraform outputs"
        ((WARNINGS++))
    fi
}

check_ansible_ssh_keys() {
    log_info "Checking Ansible SSH keys..."

    local SSH_KEY="/var/lib/jenkins/.ssh/ansible_rsa"

    if [ -f "$SSH_KEY" ]; then
        log_success "Ansible SSH key exists"

        # Check key permissions
        local PERMS=$(stat -c "%a" "$SSH_KEY")
        if [ "$PERMS" = "600" ]; then
            log_success "SSH key has correct permissions (600)"
        else
            log_warning "SSH key has incorrect permissions: $PERMS (should be 600)"
            ((WARNINGS++))
        fi
    else
        log_error "Ansible SSH key not found: $SSH_KEY"
        ((ERRORS++))
    fi
}

##############################################################################
# Port Availability Checks
##############################################################################

check_port_conflicts() {
    log_info "Checking for port conflicts..."

    # Define service ports
    declare -A SERVICE_PORTS=(
        ["orchestrator"]="9130"
        ["auth-service"]="3005:50051"
        ["users-service"]="3006:50052"
        ["matches-service"]="3007:50053"
        ["messaging-service"]="3008:50054"
        ["notification-service"]="3009:50055"
    )

    local CONFLICTS=0

    for service in "${!SERVICE_PORTS[@]}"; do
        IFS=':' read -ra PORTS <<< "${SERVICE_PORTS[$service]}"
        for port in "${PORTS[@]}"; do
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                log_warning "Port $port ($service) is already in use"
                ((CONFLICTS++))
            fi
        done
    done

    if [ $CONFLICTS -eq 0 ]; then
        log_success "No port conflicts detected"
    else
        log_warning "Found $CONFLICTS potential port conflicts"
        ((WARNINGS++))
    fi
}

##############################################################################
# Environment Checks
##############################################################################

check_environment_files() {
    log_info "Checking environment configuration files..."

    local ENV_FILE="$BTD_APP_ROOT/.env.$ENVIRONMENT"

    if [ -f "$ENV_FILE" ]; then
        log_success "Environment file exists: $ENV_FILE"

        # Check for required variables
        local REQUIRED_VARS=(
            "DATABASE_URL"
            "REDIS_URL"
            "MINIO_ENDPOINT"
            "CONSUL_HOST"
        )

        for var in "${REQUIRED_VARS[@]}"; do
            if grep -q "^$var=" "$ENV_FILE"; then
                log_success "  $var is defined"
            else
                log_error "  $var is missing"
                ((ERRORS++))
            fi
        done
    else
        log_error "Environment file not found: $ENV_FILE"
        ((ERRORS++))
    fi
}

check_credentials() {
    log_info "Checking Jenkins credentials..."

    # Check if credentials are configured (this would need Jenkins CLI or API)
    local REQUIRED_CREDENTIALS=(
        "github-pat-btd"
        "proxmox-api-token"
        "ansible-ssh-private-key"
        "consul-acl-token"
        "slack-webhook-url"
    )

    log_info "Required credentials:"
    for cred in "${REQUIRED_CREDENTIALS[@]}"; do
        echo "  - $cred"
    done

    log_warning "Manual verification required for Jenkins credentials"
    ((WARNINGS++))
}

##############################################################################
# Disk Space Checks
##############################################################################

check_disk_space() {
    log_info "Checking disk space..."

    local MIN_FREE_GB=10
    local AVAILABLE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "$AVAILABLE_GB" -gt "$MIN_FREE_GB" ]; then
        log_success "Sufficient disk space available: ${AVAILABLE_GB}GB"
    else
        log_error "Insufficient disk space: ${AVAILABLE_GB}GB (minimum: ${MIN_FREE_GB}GB)"
        ((ERRORS++))
    fi
}

##############################################################################
# Network Checks
##############################################################################

check_network_connectivity() {
    log_info "Checking network connectivity to BTD subnet..."

    # Check connectivity to key infrastructure nodes
    local NODES=(
        "10.27.27.27:Consul"
        "10.27.27.28:MinIO"
        "10.27.27.30:PostgreSQL"
        "10.27.27.26:Redis"
        "10.27.27.192:Proxmox"
    )

    for node_info in "${NODES[@]}"; do
        IFS=':' read -r ip name <<< "$node_info"
        if ping -c 1 -W 2 "$ip" &> /dev/null; then
            log_success "  $name ($ip) is reachable"
        else
            log_error "  $name ($ip) is not reachable"
            ((ERRORS++))
        fi
    done
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo "=========================================="
    echo "BTD Platform Pre-Deployment Validation"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Date: $(date)"
    echo "=========================================="
    echo ""

    # Run all checks
    check_proxmox_connectivity
    check_consul_connectivity
    check_postgresql
    check_redis
    check_minio
    echo ""

    check_terraform_installation
    check_terraform_state
    echo ""

    check_ansible_installation
    check_ansible_inventory
    check_ansible_ssh_keys
    echo ""

    check_port_conflicts
    echo ""

    check_environment_files
    check_credentials
    echo ""

    check_disk_space
    check_network_connectivity
    echo ""

    # Summary
    echo "=========================================="
    echo "Validation Summary"
    echo "=========================================="
    echo -e "Errors:   ${RED}$ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo "=========================================="

    if [ $ERRORS -gt 0 ]; then
        log_error "Pre-deployment validation failed with $ERRORS errors"
        exit 1
    elif [ $WARNINGS -gt 0 ]; then
        log_warning "Pre-deployment validation passed with $WARNINGS warnings"
        exit 0
    else
        log_success "Pre-deployment validation passed successfully"
        exit 0
    fi
}

# Run main function
main
