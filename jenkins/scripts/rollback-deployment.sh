#!/bin/bash

##############################################################################
# BTD Platform - Rollback Deployment Script
#
# Purpose: Rollback to previous deployment state
# Usage: ./rollback-deployment.sh <deployment_id> <environment> [services]
#
# Network: 10.27.27.0/23
##############################################################################

set -euo pipefail

# Configuration
DEPLOYMENT_ID="${1:-}"
ENVIRONMENT="${2:-development}"
SERVICES="${3:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BTD_APP_ROOT="/root/projects/btd-app"
ANSIBLE_DIR="$BTD_APP_ROOT/btd-ansible"
ROLLBACK_STATE_DIR="/var/lib/jenkins/rollback-states"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

##############################################################################
# Validation
##############################################################################

validate_inputs() {
    log_info "Validating rollback parameters..."

    if [ -z "$DEPLOYMENT_ID" ]; then
        log_error "Deployment ID is required"
        echo "Usage: $0 <deployment_id> <environment> [services]"
        exit 1
    fi

    if [ ! -d "$ANSIBLE_DIR" ]; then
        log_error "Ansible directory not found: $ANSIBLE_DIR"
        exit 1
    fi

    log_success "Input validation passed"
}

##############################################################################
# Find Previous Deployment
##############################################################################

find_previous_deployment() {
    log_info "Finding previous successful deployment..."

    mkdir -p "$ROLLBACK_STATE_DIR"

    # List all deployment states, sorted by date
    local STATES=$(find "$ROLLBACK_STATE_DIR" -name "deployment-*.json" -type f -printf "%T@ %p\n" | sort -rn)

    if [ -z "$STATES" ]; then
        log_error "No previous deployment states found"
        return 1
    fi

    # Find the state before the failed deployment
    local PREVIOUS_STATE=""
    while IFS= read -r line; do
        local state_file=$(echo "$line" | awk '{print $2}')
        local state_deployment_id=$(jq -r '.deployment_id' "$state_file" 2>/dev/null || echo "")

        if [ "$state_deployment_id" != "$DEPLOYMENT_ID" ] && [ -n "$state_deployment_id" ]; then
            PREVIOUS_STATE="$state_file"
            break
        fi
    done <<< "$STATES"

    if [ -z "$PREVIOUS_STATE" ]; then
        log_error "No previous deployment state found to rollback to"
        return 1
    fi

    log_success "Found previous deployment state: $(basename "$PREVIOUS_STATE")"
    echo "$PREVIOUS_STATE"
}

##############################################################################
# Stop Failed Services
##############################################################################

stop_failed_services() {
    log_info "Stopping failed services..."

    local service_list=$1

    cd "$ANSIBLE_DIR"

    # Create Ansible playbook to stop services
    cat > /tmp/stop-services.yml << 'EOF'
---
- name: Stop Failed Services
  hosts: all
  become: yes
  tasks:
    - name: Stop systemd service
      systemd:
        name: "{{ item }}"
        state: stopped
      loop: "{{ services_to_stop.split(',') }}"
      when: services_to_stop != 'all'
      ignore_errors: yes

    - name: Stop all BTD services (if 'all')
      shell: |
        systemctl stop btd-*.service
      when: services_to_stop == 'all'
      ignore_errors: yes
EOF

    ansible-playbook \
        -i "inventories/$ENVIRONMENT/hosts.yml" \
        /tmp/stop-services.yml \
        --extra-vars "services_to_stop=$service_list" \
        -v || log_warning "Some services may not have stopped cleanly"

    log_success "Services stopped"
}

##############################################################################
# Restore Previous Code
##############################################################################

restore_previous_code() {
    log_info "Restoring previous code version..."

    local previous_state_file=$1
    local git_commit=$(jq -r '.git_commit // "unknown"' "$previous_state_file")

    if [ "$git_commit" != "unknown" ] && [ -n "$git_commit" ]; then
        log_info "Checking out commit: $git_commit"

        cd "$BTD_APP_ROOT"

        # Stash any local changes
        git stash save "Pre-rollback stash $(date +%Y%m%d-%H%M%S)" || true

        # Checkout previous commit
        if git checkout "$git_commit"; then
            log_success "Code restored to commit: $git_commit"
        else
            log_error "Failed to checkout commit: $git_commit"
            return 1
        fi
    else
        log_warning "No Git commit information in previous state, skipping code restore"
    fi
}

##############################################################################
# Rebuild Services
##############################################################################

rebuild_services() {
    log_info "Rebuilding services..."

    local service_list=$1

    cd "$BTD_APP_ROOT"

    if [ "$service_list" = "all" ]; then
        # Build all services
        local MICROSERVICES=(
            "btd-auth-service"
            "btd-users-service"
            "btd-matches-service"
            "btd-messaging-service"
            "btd-notification-service"
            "btd-payment-service"
            "btd-admin-service"
            "btd-analytics-service"
            "btd-ai-service"
            "btd-job-processing-service"
            "btd-location-service"
            "btd-match-request-limits-service"
            "btd-moderation-service"
            "btd-permission-service"
            "btd-travel-service"
            "btd-video-call-service"
            "btd-orchestrator"
            "file-processing-service"
        )
    else
        IFS=',' read -ra MICROSERVICES <<< "$service_list"
    fi

    for service in "${MICROSERVICES[@]}"; do
        log_info "Building $service..."

        if [ -d "$service" ]; then
            cd "$service"

            npm ci || {
                log_error "Failed to install dependencies for $service"
                cd "$BTD_APP_ROOT"
                continue
            }

            npm run build || {
                log_error "Failed to build $service"
                cd "$BTD_APP_ROOT"
                continue
            }

            # Copy proto files
            if [ -d "src/proto" ]; then
                mkdir -p dist/src
                cp -r src/proto dist/src/
            fi

            log_success "$service rebuilt successfully"
            cd "$BTD_APP_ROOT"
        else
            log_warning "Service directory not found: $service"
        fi
    done

    log_success "Services rebuilt"
}

##############################################################################
# Restore Database State (if needed)
##############################################################################

restore_database_state() {
    log_info "Checking if database rollback is needed..."

    local previous_state_file=$1
    local db_version=$(jq -r '.database_version // "unknown"' "$previous_state_file")

    if [ "$db_version" != "unknown" ] && [ -n "$db_version" ]; then
        log_warning "Database migration rollback detected (version: $db_version)"
        log_warning "Manual database rollback may be required"
        log_info "Use: npm run prisma:migrate:resolve -- --rolled-back <migration_name>"
    else
        log_info "No database rollback needed"
    fi
}

##############################################################################
# Redeploy Services
##############################################################################

redeploy_services() {
    log_info "Redeploying services with Ansible..."

    local service_list=$1

    cd "$ANSIBLE_DIR"

    local extra_vars="environment=$ENVIRONMENT rollback=true"

    if [ "$service_list" != "all" ]; then
        extra_vars="$extra_vars services_filter=$service_list"
    fi

    ansible-playbook \
        -i "inventories/$ENVIRONMENT/hosts.yml" \
        playbooks/deploy-services.yml \
        --extra-vars "$extra_vars" \
        --diff \
        -v || {
            log_error "Ansible deployment failed during rollback"
            return 1
        }

    log_success "Services redeployed"
}

##############################################################################
# Restart Services
##############################################################################

restart_services() {
    log_info "Restarting services..."

    local service_list=$1

    cd "$ANSIBLE_DIR"

    cat > /tmp/restart-services.yml << 'EOF'
---
- name: Restart Services
  hosts: all
  become: yes
  tasks:
    - name: Restart specific services
      systemd:
        name: "{{ item }}"
        state: restarted
        daemon_reload: yes
      loop: "{{ services_to_restart.split(',') }}"
      when: services_to_restart != 'all'

    - name: Restart all BTD services
      shell: |
        systemctl daemon-reload
        systemctl restart btd-*.service
      when: services_to_restart == 'all'

    - name: Wait for services to be ready
      wait_for:
        port: "{{ item.port }}"
        delay: 5
        timeout: 60
      loop:
        - { port: 9130 }  # Orchestrator
        - { port: 50051 } # Auth service
      when: services_to_restart == 'all'
      ignore_errors: yes
EOF

    ansible-playbook \
        -i "inventories/$ENVIRONMENT/hosts.yml" \
        /tmp/restart-services.yml \
        --extra-vars "services_to_restart=$service_list" \
        -v

    # Wait for services to stabilize
    log_info "Waiting for services to stabilize (30 seconds)..."
    sleep 30

    log_success "Services restarted"
}

##############################################################################
# Verify Rollback
##############################################################################

verify_rollback() {
    log_info "Verifying rollback success..."

    # Run health checks
    if [ -f "$SCRIPT_DIR/post-deployment-health-check.sh" ]; then
        bash "$SCRIPT_DIR/post-deployment-health-check.sh" "$ENVIRONMENT" || {
            log_error "Health checks failed after rollback"
            return 1
        }
    else
        log_warning "Health check script not found, skipping verification"
    fi

    log_success "Rollback verification passed"
}

##############################################################################
# Save Rollback Record
##############################################################################

save_rollback_record() {
    log_info "Saving rollback record..."

    local rollback_record_file="$ROLLBACK_STATE_DIR/rollback-$(date +%Y%m%d-%H%M%S).json"

    cat > "$rollback_record_file" << EOF
{
    "rollback_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "failed_deployment_id": "$DEPLOYMENT_ID",
    "environment": "$ENVIRONMENT",
    "services_rolled_back": "$SERVICES",
    "rollback_method": "automated"
}
EOF

    log_success "Rollback record saved: $(basename "$rollback_record_file")"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo "=========================================="
    echo "BTD Platform Deployment Rollback"
    echo "=========================================="
    echo "Failed Deployment ID: $DEPLOYMENT_ID"
    echo "Environment: $ENVIRONMENT"
    echo "Services: $SERVICES"
    echo "Date: $(date)"
    echo "=========================================="
    echo ""

    # Validate inputs
    validate_inputs

    # Find previous deployment state
    PREVIOUS_STATE=$(find_previous_deployment) || {
        log_error "Cannot proceed without previous deployment state"
        exit 1
    }

    log_info "Rolling back to: $(jq -r '.deployment_id' "$PREVIOUS_STATE")"

    # Confirmation
    log_warning "This will rollback the deployment. Continue? (yes/no)"
    read -r -p "Answer: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Rollback cancelled by user"
        exit 0
    fi

    # Execute rollback steps
    stop_failed_services "$SERVICES"
    restore_previous_code "$PREVIOUS_STATE"
    restore_database_state "$PREVIOUS_STATE"
    rebuild_services "$SERVICES"
    redeploy_services "$SERVICES"
    restart_services "$SERVICES"
    verify_rollback

    # Save rollback record
    save_rollback_record

    echo ""
    echo "=========================================="
    echo "Rollback Complete"
    echo "=========================================="
    log_success "Deployment rolled back successfully"
    log_info "Failed deployment: $DEPLOYMENT_ID"
    log_info "Restored to: $(jq -r '.deployment_id' "$PREVIOUS_STATE")"
    echo "=========================================="

    exit 0
}

# Run main function
main
