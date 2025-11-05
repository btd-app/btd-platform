# BTD Service IP Mapping

**Last Updated**: 2025-11-03

## Production Environment (10.27.27.x)

| Service | IP Address | HTTP Port | gRPC Port | Container ID |
|---------|-----------|-----------|-----------|--------------|
| btd-auth-service | 10.27.27.80 | 3005 | 50051 | TBD |
| btd-users-service | 10.27.27.81 | 3000 | 50052 | TBD |
| btd-messaging-service | 10.27.27.82 | 3001 | 50054 | TBD |
| btd-matches-service | 10.27.27.83 | 3002 | 50055 | TBD |
| btd-analytics-service | 10.27.27.84 | 3003 | 50053 | TBD |
| btd-video-call-service | 10.27.27.85 | 3004 | 50056 | TBD |
| btd-travel-service | 10.27.27.86 | 3006 | 50057 | TBD |
| btd-moderation-service | 10.27.27.87 | 3007 | 50058 | TBD |
| btd-permission-service | 10.27.27.88 | 3008 | 50059 | TBD |
| btd-notification-service | 10.27.27.89 | 3030 | 50060 | TBD |
| btd-payment-service | 10.27.27.90 | 3010 | 50061 | TBD |
| btd-admin-service | 10.27.27.91 | 3011 | 50062 | TBD |
| btd-ai-service | 10.27.27.92 | 3012 | 50063 | TBD |
| btd-job-processing-service | 10.27.27.93 | 3013 | 50064 | TBD |
| btd-location-service | 10.27.27.94 | 3014 | 50065 | TBD |
| btd-match-request-limits-service | 10.27.27.95 | 3015 | 50066 | TBD |
| file-processing-service | 10.27.27.96 | 3016 | 50067 | TBD |
| btd-orchestrator | 10.27.27.97 | 9130 | N/A | TBD |

## Staging Environment (10.27.26.180-197)

| Service | IP Address | HTTP Port | gRPC Port |
|---------|-----------|-----------|-----------|
| btd-auth-service | 10.27.26.180 | 3005 | 50051 |
| btd-users-service | 10.27.26.181 | 3000 | 50052 |
| btd-messaging-service | 10.27.26.182 | 3001 | 50054 |
| btd-matches-service | 10.27.26.183 | 3002 | 50055 |
| btd-analytics-service | 10.27.26.184 | 3003 | 50053 |
| btd-video-call-service | 10.27.26.185 | 3004 | 50056 |
| btd-travel-service | 10.27.26.186 | 3006 | 50057 |
| btd-moderation-service | 10.27.26.187 | 3007 | 50058 |
| btd-permission-service | 10.27.26.188 | 3008 | 50059 |
| btd-notification-service | 10.27.26.189 | 3030 | 50060 |
| btd-payment-service | 10.27.26.190 | 3010 | 50061 |
| btd-admin-service | 10.27.26.191 | 3011 | 50062 |
| btd-ai-service | 10.27.26.192 | 3012 | 50063 |
| btd-job-processing-service | 10.27.26.193 | 3013 | 50064 |
| btd-location-service | 10.27.26.194 | 3014 | 50065 |
| btd-match-request-limits-service | 10.27.26.195 | 3015 | 50066 |
| file-processing-service | 10.27.26.196 | 3016 | 50067 |
| btd-orchestrator | 10.27.26.197 | 9130 | N/A |

## Development Environment (10.27.26.80-97)

| Service | IP Address | HTTP Port | gRPC Port | Status |
|---------|-----------|-----------|-----------|--------|
| btd-auth-service | 10.27.26.80 | 3005 | 50051 | ✅ Active |
| btd-users-service | 10.27.26.81 | 3000 | 50052 | Pending |
| btd-messaging-service | 10.27.26.82 | 3001 | 50054 | Pending |
| btd-matches-service | 10.27.26.83 | 3002 | 50055 | Pending |
| btd-analytics-service | 10.27.26.84 | 3003 | 50053 | ✅ Active |
| btd-video-call-service | 10.27.26.85 | 3004 | 50056 | Pending |
| btd-travel-service | 10.27.26.86 | 3006 | 50057 | Pending |
| btd-moderation-service | 10.27.26.87 | 3007 | 50058 | Pending |
| btd-permission-service | 10.27.26.88 | 3008 | 50059 | Pending |
| btd-notification-service | 10.27.26.89 | 3030 | 50060 | Pending |
| btd-payment-service | 10.27.26.90 | 3010 | 50061 | Pending |
| btd-admin-service | 10.27.26.91 | 3011 | 50062 | Pending |
| btd-ai-service | 10.27.26.92 | 3012 | 50063 | Pending |
| btd-job-processing-service | 10.27.26.93 | 3013 | 50064 | Pending |
| btd-location-service | 10.27.26.94 | 3014 | 50065 | Pending |
| btd-match-request-limits-service | 10.27.26.95 | 3015 | 50066 | Pending |
| file-processing-service | 10.27.26.96 | 3016 | 50067 | Pending |
| btd-orchestrator | 10.27.26.97 | 9130 | N/A | Pending |

## Core Infrastructure

| Service | IP Address | Port | Purpose |
|---------|-----------|------|---------|
| PostgreSQL | 10.27.27.70 | 5432 | Primary database server |
| Redis (Development) | 10.27.27.68 | 6379 | Dev caching and pub/sub |
| Redis (Staging) | 10.27.27.69 | 6379 | Staging caching and pub/sub |
| Redis (Production) | 10.27.27.71 | 6379 | Prod caching and pub/sub |
| MinIO | 10.27.27.72 | 9000, 9001 | Object storage |
| Verdaccio | 10.27.27.18 | 4873 | Private npm registry |
| HAProxy | 10.27.27.74 | 80, 443 | Load balancer |
| Prometheus/Grafana | 10.27.27.75 | 9090, 3000 | Monitoring |
| Consul-1 | 10.27.27.27 | 8500, 8600 | Service discovery |
| Consul-2 | 10.27.27.115 | 8500, 8600 | Service discovery |
| Consul-3 | 10.27.27.116 | 8500, 8600 | Service discovery |
| Jenkins | 10.27.27.251 | 8080 | CI/CD server |
| Ansible LXC | 10.27.27.181 | 22 | Automation hub |

## Notes

- All services use standardized port ranges
- gRPC ports increment sequentially from 50051
- HTTP ports vary based on service requirements
- Container IDs to be documented as services are deployed

## See Also

- [Port Registry](port-registry.md)
- [Network Topology](network-topology.md)
