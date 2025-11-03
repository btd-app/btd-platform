#!/bin/bash

##############################################################################
# BTD Platform - Smoke Tests Script
#
# Purpose: Run basic functionality tests to verify critical paths
# Usage: ./smoke-tests.sh <environment>
#
# Network: 10.27.27.0/23
##############################################################################

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Environment-specific endpoints
case "$ENVIRONMENT" in
    production)
        ORCHESTRATOR_URL="http://10.27.27.100:9130"
        ;;
    staging)
        ORCHESTRATOR_URL="http://10.27.27.150:9130"
        ;;
    *)
        ORCHESTRATOR_URL="http://10.27.27.200:9130"
        ;;
esac

API_BASE="$ORCHESTRATOR_URL/api/v1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

##############################################################################
# Test Helper Functions
##############################################################################

# Make HTTP request and check response
http_test() {
    local test_name=$1
    local method=$2
    local endpoint=$3
    local expected_status=$4
    local data=${5:-""}
    local headers=${6:-""}

    log_info "Testing: $test_name"

    local curl_cmd="curl -s -w '\n%{http_code}' -X $method"

    if [ -n "$headers" ]; then
        curl_cmd="$curl_cmd -H '$headers'"
    fi

    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data' -H 'Content-Type: application/json'"
    fi

    curl_cmd="$curl_cmd '$endpoint'"

    local response=$(eval $curl_cmd 2>&1)
    local status_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)

    if [ "$status_code" = "$expected_status" ]; then
        log_success "$test_name (HTTP $status_code)"
        return 0
    else
        log_failure "$test_name (Expected: $expected_status, Got: $status_code)"
        echo "Response: $body"
        return 1
    fi
}

##############################################################################
# Infrastructure Tests
##############################################################################

test_infrastructure() {
    echo ""
    echo "=========================================="
    echo "Infrastructure Smoke Tests"
    echo "=========================================="

    # Test database connectivity
    log_info "Testing PostgreSQL connectivity..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.27.27.30/5432" 2>/dev/null; then
        log_success "PostgreSQL is accessible"
    else
        log_failure "PostgreSQL is not accessible"
    fi

    # Test Redis connectivity
    log_info "Testing Redis connectivity..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.27.27.26/6379" 2>/dev/null; then
        log_success "Redis is accessible"
    else
        log_failure "Redis is not accessible"
    fi

    # Test MinIO connectivity
    log_info "Testing MinIO connectivity..."
    if curl -s --max-time 5 "http://10.27.27.28:9000/minio/health/live" > /dev/null; then
        log_success "MinIO is accessible"
    else
        log_failure "MinIO is not accessible"
    fi

    # Test Consul connectivity
    log_info "Testing Consul connectivity..."
    if curl -s --max-time 5 "http://10.27.27.27:8500/v1/status/leader" > /dev/null; then
        log_success "Consul is accessible"
    else
        log_failure "Consul is not accessible"
    fi
}

##############################################################################
# API Health Tests
##############################################################################

test_api_health() {
    echo ""
    echo "=========================================="
    echo "API Health Tests"
    echo "=========================================="

    # Test orchestrator health endpoint
    http_test "Orchestrator Health Check" "GET" "$API_BASE/health" "200"

    # Test if API is responding
    local response=$(curl -s --max-time 5 "$API_BASE/health" 2>/dev/null || echo "")
    if echo "$response" | jq -e '.status == "ok"' > /dev/null 2>&1; then
        log_success "Orchestrator health endpoint returns valid JSON"
    elif [ -n "$response" ]; then
        log_failure "Orchestrator health endpoint returns invalid JSON: $response"
    else
        log_failure "Orchestrator health endpoint is not responding"
    fi
}

##############################################################################
# Authentication Tests
##############################################################################

test_authentication() {
    echo ""
    echo "=========================================="
    echo "Authentication Tests"
    echo "=========================================="

    # Test login endpoint exists (expect 400 or 401 without credentials, not 404)
    log_info "Testing login endpoint availability..."
    local status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE/auth/login" -H "Content-Type: application/json" -d '{}')

    if [ "$status" = "400" ] || [ "$status" = "401" ] || [ "$status" = "422" ]; then
        log_success "Login endpoint is available (HTTP $status)"
    elif [ "$status" = "404" ]; then
        log_failure "Login endpoint not found (HTTP 404)"
    else
        log_failure "Login endpoint returned unexpected status: HTTP $status"
    fi

    # Test register endpoint exists
    log_info "Testing register endpoint availability..."
    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE/auth/register" -H "Content-Type: application/json" -d '{}')

    if [ "$status" = "400" ] || [ "$status" = "422" ]; then
        log_success "Register endpoint is available (HTTP $status)"
    elif [ "$status" = "404" ]; then
        log_failure "Register endpoint not found (HTTP 404)"
    else
        log_warning "Register endpoint returned: HTTP $status"
    fi
}

##############################################################################
# Service Discovery Tests
##############################################################################

test_service_discovery() {
    echo ""
    echo "=========================================="
    echo "Service Discovery Tests"
    echo "=========================================="

    log_info "Testing Consul service registration..."

    local services=$(curl -s "http://10.27.27.27:8500/v1/agent/services" | jq -r 'keys[]' 2>/dev/null || echo "")

    if [ -n "$services" ]; then
        log_success "Services registered in Consul:"

        local registered_count=0
        echo "$services" | while read -r service; do
            echo "  - $service"
            ((registered_count++))
        done

        if [ $registered_count -gt 0 ]; then
            log_success "Found $registered_count registered services"
        fi
    else
        log_failure "No services registered in Consul"
    fi
}

##############################################################################
# gRPC Service Tests
##############################################################################

test_grpc_services() {
    echo ""
    echo "=========================================="
    echo "gRPC Service Tests"
    echo "=========================================="

    # Test gRPC port connectivity for critical services
    declare -A GRPC_SERVICES=(
        ["auth-service"]="10.27.27.101:50051"
        ["users-service"]="10.27.27.102:50052"
        ["orchestrator"]="10.27.27.100:50051"
    )

    for service in "${!GRPC_SERVICES[@]}"; do
        log_info "Testing $service gRPC port..."
        IFS=':' read -r host port <<< "${GRPC_SERVICES[$service]}"

        if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
            log_success "$service gRPC port is open"
        else
            log_failure "$service gRPC port is not accessible"
        fi
    done
}

##############################################################################
# Database Tests
##############################################################################

test_database_operations() {
    echo ""
    echo "=========================================="
    echo "Database Tests"
    echo "=========================================="

    log_info "Testing database connectivity through services..."

    # This would require a test endpoint that queries the database
    # For now, we'll just verify the database is reachable
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.27.27.30/5432" 2>/dev/null; then
        log_success "Database port is accessible"
    else
        log_failure "Cannot reach database"
    fi
}

##############################################################################
# Cache Tests
##############################################################################

test_cache_operations() {
    echo ""
    echo "=========================================="
    echo "Cache Tests"
    echo "=========================================="

    log_info "Testing Redis cache connectivity..."

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.27.27.26/6379" 2>/dev/null; then
        log_success "Redis cache is accessible"
    else
        log_failure "Cannot reach Redis cache"
    fi
}

##############################################################################
# Critical User Flows
##############################################################################

test_critical_user_flows() {
    echo ""
    echo "=========================================="
    echo "Critical User Flow Tests"
    echo "=========================================="

    log_info "Testing user registration flow..."

    # Test data
    local test_email="smoke-test-$(date +%s)@example.com"
    local test_data='{
        "email": "'$test_email'",
        "password": "TestPassword123!",
        "username": "smoketest'$(date +%s)'"
    }'

    # Attempt registration (expect success or validation error, not 500)
    local response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/auth/register" \
        -H "Content-Type: application/json" \
        -d "$test_data" 2>&1)

    local status_code=$(echo "$response" | tail -n1)

    if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
        log_success "User registration flow is working"
    elif [ "$status_code" = "400" ] || [ "$status_code" = "422" ]; then
        log_warning "Registration endpoint is available but rejected test data (HTTP $status_code)"
        ((TESTS_PASSED++))
    elif [ "$status_code" = "500" ]; then
        log_failure "Registration endpoint returned server error (HTTP 500)"
    else
        log_warning "Registration endpoint returned: HTTP $status_code"
    fi
}

##############################################################################
# Load and Performance
##############################################################################

test_basic_load() {
    echo ""
    echo "=========================================="
    echo "Basic Load Test"
    echo "=========================================="

    log_info "Testing orchestrator response time..."

    local start_time=$(date +%s%N)
    curl -s --max-time 10 "$API_BASE/health" > /dev/null
    local end_time=$(date +%s%N)

    local response_time=$(( (end_time - start_time) / 1000000 ))

    log_info "Response time: ${response_time}ms"

    if [ $response_time -lt 1000 ]; then
        log_success "Response time is good (< 1 second)"
    elif [ $response_time -lt 3000 ]; then
        log_warning "Response time is acceptable (< 3 seconds)"
        ((TESTS_PASSED++))
    else
        log_failure "Response time is too slow (> 3 seconds)"
    fi
}

##############################################################################
# End-to-End Test
##############################################################################

test_end_to_end() {
    echo ""
    echo "=========================================="
    echo "End-to-End Test"
    echo "=========================================="

    log_info "Running end-to-end flow test..."

    # Test complete flow: health -> login attempt -> check response
    local health_ok=false
    local login_ok=false

    # Check health
    if curl -s --max-time 5 "$API_BASE/health" | jq -e '.status == "ok"' > /dev/null 2>&1; then
        health_ok=true
    fi

    # Check login endpoint
    local login_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"test"}')

    if [ "$login_status" != "404" ] && [ "$login_status" != "500" ]; then
        login_ok=true
    fi

    if [ "$health_ok" = true ] && [ "$login_ok" = true ]; then
        log_success "End-to-end flow test passed"
    else
        log_failure "End-to-end flow test failed (health: $health_ok, login: $login_ok)"
    fi
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo "=========================================="
    echo "BTD Platform Smoke Tests"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Orchestrator: $ORCHESTRATOR_URL"
    echo "Date: $(date)"
    echo "=========================================="

    # Run all smoke tests
    test_infrastructure
    test_api_health
    test_authentication
    test_service_discovery
    test_grpc_services
    test_database_operations
    test_cache_operations
    test_critical_user_flows
    test_basic_load
    test_end_to_end

    # Summary
    echo ""
    echo "=========================================="
    echo "Smoke Test Summary"
    echo "=========================================="
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    if [ $total_tests -gt 0 ]; then
        local pass_rate=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED/$total_tests)*100}")
        echo "Pass Rate: ${pass_rate}%"
    fi
    echo "=========================================="

    if [ $TESTS_FAILED -gt 0 ]; then
        log_failure "Smoke tests failed ($TESTS_FAILED failures)"
        exit 1
    else
        log_success "All smoke tests passed!"
        exit 0
    fi
}

# Run main function
main
