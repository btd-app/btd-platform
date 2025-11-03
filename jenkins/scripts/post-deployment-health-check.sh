#!/bin/bash

##############################################################################
# BTD Platform - Post-Deployment Health Check Script
#
# Purpose: Verify all services are healthy after deployment
# Usage: ./post-deployment-health-check.sh <environment>
#
# Network: 10.27.27.0/23
##############################################################################

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_RETRIES=30
RETRY_DELAY=10

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

# Health check counters
HEALTHY_SERVICES=0
UNHEALTHY_SERVICES=0

##############################################################################
# Service Health Check Functions
##############################################################################

check_http_health() {
    local service_name=$1
    local health_url=$2
    local retry_count=0

    log_info "Checking $service_name health..."

    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -s -f --max-time 5 "$health_url" > /dev/null 2>&1; then
            log_success "$service_name is healthy"
            ((HEALTHY_SERVICES++))
            return 0
        fi

        ((retry_count++))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warning "$service_name not ready, retrying ($retry_count/$MAX_RETRIES)..."
            sleep $RETRY_DELAY
        fi
    done

    log_error "$service_name is unhealthy after $MAX_RETRIES attempts"
    ((UNHEALTHY_SERVICES++))
    return 1
}

check_grpc_health() {
    local service_name=$1
    local host=$2
    local port=$3

    log_info "Checking $service_name gRPC connectivity..."

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        log_success "$service_name gRPC port is open"
        ((HEALTHY_SERVICES++))
        return 0
    else
        log_error "$service_name gRPC port is not accessible"
        ((UNHEALTHY_SERVICES++))
        return 1
    fi
}

check_database_connectivity() {
    log_info "Checking database connectivity..."

    local POSTGRES_HOST="10.27.27.30"
    local POSTGRES_PORT="5432"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT" 2>/dev/null; then
        log_success "PostgreSQL is accessible"
        return 0
    else
        log_error "PostgreSQL is not accessible"
        return 1
    fi
}

check_redis_connectivity() {
    log_info "Checking Redis connectivity..."

    local REDIS_HOST="10.27.27.26"
    local REDIS_PORT="6379"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$REDIS_HOST/$REDIS_PORT" 2>/dev/null; then
        log_success "Redis is accessible"
        return 0
    else
        log_error "Redis is not accessible"
        return 1
    fi
}

check_consul_services() {
    log_info "Checking Consul service registration..."

    local CONSUL_ADDR="10.27.27.27:8500"
    local services=$(curl -s "http://$CONSUL_ADDR/v1/agent/services" | jq -r 'keys[]' 2>/dev/null || echo "")

    if [ -n "$services" ]; then
        log_success "Consul has registered services:"
        echo "$services" | while read -r service; do
            echo "  - $service"
        done
        return 0
    else
        log_warning "No services registered in Consul or Consul is not accessible"
        return 1
    fi
}

##############################################################################
# Infrastructure Service Checks
##############################################################################

check_infrastructure_services() {
    echo ""
    echo "=========================================="
    echo "Infrastructure Services Health"
    echo "=========================================="

    check_database_connectivity
    check_redis_connectivity
    check_consul_services

    # Check MinIO
    if curl -s --max-time 5 "http://10.27.27.28:9000/minio/health/live" > /dev/null; then
        log_success "MinIO is healthy"
    else
        log_error "MinIO is not accessible"
    fi
}

##############################################################################
# Microservice Health Checks
##############################################################################

check_microservices() {
    echo ""
    echo "=========================================="
    echo "Microservices Health"
    echo "=========================================="

    # Define service endpoints (adjust based on your environment)
    declare -A HTTP_SERVICES=(
        ["orchestrator"]="http://10.27.27.100:9130/api/v1/health"
    )

    declare -A GRPC_SERVICES=(
        ["auth-service"]="10.27.27.101:50051"
        ["users-service"]="10.27.27.102:50052"
        ["matches-service"]="10.27.27.103:50053"
        ["messaging-service"]="10.27.27.104:50054"
        ["notification-service"]="10.27.27.105:50055"
        ["payment-service"]="10.27.27.106:50056"
        ["admin-service"]="10.27.27.107:50057"
        ["analytics-service"]="10.27.27.108:50058"
        ["ai-service"]="10.27.27.109:50059"
        ["job-processing-service"]="10.27.27.110:50060"
        ["location-service"]="10.27.27.111:50061"
        ["match-request-limits-service"]="10.27.27.112:50062"
        ["moderation-service"]="10.27.27.113:50063"
        ["permission-service"]="10.27.27.114:50064"
        ["travel-service"]="10.27.27.115:50065"
        ["video-call-service"]="10.27.27.116:50066"
        ["file-processing-service"]="10.27.27.117:50067"
    )

    # Check HTTP services
    for service in "${!HTTP_SERVICES[@]}"; do
        check_http_health "$service" "${HTTP_SERVICES[$service]}"
    done

    # Check gRPC services
    for service in "${!GRPC_SERVICES[@]}"; do
        IFS=':' read -r host port <<< "${GRPC_SERVICES[$service]}"
        check_grpc_health "$service" "$host" "$port"
    done
}

##############################################################################
# Service Log Checks
##############################################################################

check_service_logs() {
    echo ""
    echo "=========================================="
    echo "Service Log Analysis"
    echo "=========================================="

    log_info "Checking for errors in recent logs..."

    local LOG_DIR="/var/log/btd"
    if [ ! -d "$LOG_DIR" ]; then
        log_warning "Log directory not found: $LOG_DIR"
        return 0
    fi

    local ERROR_COUNT=0
    local CRITICAL_COUNT=0

    # Check for errors in last 5 minutes
    find "$LOG_DIR" -name "*.log" -type f -mmin -5 2>/dev/null | while read -r logfile; do
        local errors=$(grep -i "ERROR" "$logfile" 2>/dev/null | wc -l)
        local critical=$(grep -i "CRITICAL\|FATAL" "$logfile" 2>/dev/null | wc -l)

        if [ $errors -gt 0 ] || [ $critical -gt 0 ]; then
            log_warning "$(basename "$logfile"): $errors errors, $critical critical"
            ((ERROR_COUNT += errors))
            ((CRITICAL_COUNT += critical))
        fi
    done

    if [ $CRITICAL_COUNT -gt 0 ]; then
        log_error "Found $CRITICAL_COUNT critical errors in recent logs"
    elif [ $ERROR_COUNT -gt 10 ]; then
        log_warning "Found $ERROR_COUNT errors in recent logs (might be normal)"
    else
        log_success "No significant errors in recent logs"
    fi
}

##############################################################################
# Detailed Service Status
##############################################################################

get_detailed_service_status() {
    echo ""
    echo "=========================================="
    echo "Detailed Service Status"
    echo "=========================================="

    # This would query systemd status on each container
    log_info "Service status via systemd (if available):"

    local SERVICES=(
        "btd-orchestrator"
        "btd-auth-service"
        "btd-users-service"
    )

    for service in "${SERVICES[@]}"; do
        # This would need to run on the actual container
        # For now, just indicate what would be checked
        echo "  - $service: (status check requires container access)"
    done
}

##############################################################################
# Endpoint Tests
##############################################################################

test_critical_endpoints() {
    echo ""
    echo "=========================================="
    echo "Critical Endpoint Tests"
    echo "=========================================="

    # Test orchestrator health endpoint
    log_info "Testing orchestrator health endpoint..."
    if curl -s -f "http://10.27.27.100:9130/api/v1/health" | jq -e '.status == "ok"' > /dev/null 2>&1; then
        log_success "Orchestrator health endpoint is working"
    else
        log_error "Orchestrator health endpoint is not responding correctly"
    fi

    # Test a sample API endpoint (without authentication)
    log_info "Testing public API endpoint..."
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://10.27.27.100:9130/api/v1/health")
    if [ "$response_code" = "200" ]; then
        log_success "Public API endpoint is accessible (HTTP $response_code)"
    else
        log_warning "Public API returned HTTP $response_code"
    fi
}

##############################################################################
# Memory and Resource Checks
##############################################################################

check_resource_usage() {
    echo ""
    echo "=========================================="
    echo "Resource Usage"
    echo "=========================================="

    # Check system memory
    local MEM_TOTAL=$(free -g | awk 'NR==2 {print $2}')
    local MEM_USED=$(free -g | awk 'NR==2 {print $3}')
    local MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED/$MEM_TOTAL)*100}")

    log_info "System memory: ${MEM_USED}GB / ${MEM_TOTAL}GB (${MEM_PERCENT}%)"

    if [ "$MEM_PERCENT" -gt 90 ]; then
        log_error "Memory usage is critically high (${MEM_PERCENT}%)"
    elif [ "$MEM_PERCENT" -gt 80 ]; then
        log_warning "Memory usage is high (${MEM_PERCENT}%)"
    else
        log_success "Memory usage is normal (${MEM_PERCENT}%)"
    fi

    # Check disk usage
    local DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    log_info "Disk usage: ${DISK_USAGE}%"

    if [ "$DISK_USAGE" -gt 90 ]; then
        log_error "Disk usage is critically high (${DISK_USAGE}%)"
    elif [ "$DISK_USAGE" -gt 80 ]; then
        log_warning "Disk usage is high (${DISK_USAGE}%)"
    else
        log_success "Disk usage is normal (${DISK_USAGE}%)"
    fi
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo "=========================================="
    echo "BTD Platform Post-Deployment Health Check"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Date: $(date)"
    echo "Max Retries: $MAX_RETRIES"
    echo "Retry Delay: ${RETRY_DELAY}s"
    echo "=========================================="

    # Run all health checks
    check_infrastructure_services
    check_microservices
    check_service_logs
    get_detailed_service_status
    test_critical_endpoints
    check_resource_usage

    # Summary
    echo ""
    echo "=========================================="
    echo "Health Check Summary"
    echo "=========================================="
    echo -e "Healthy Services:   ${GREEN}$HEALTHY_SERVICES${NC}"
    echo -e "Unhealthy Services: ${RED}$UNHEALTHY_SERVICES${NC}"
    echo "=========================================="

    if [ $UNHEALTHY_SERVICES -gt 0 ]; then
        log_error "Deployment verification failed: $UNHEALTHY_SERVICES services are unhealthy"
        exit 1
    else
        log_success "All services are healthy! Deployment verified successfully"
        exit 0
    fi
}

# Run main function
main
