# Consul backend for state management (temporarily disabled for import)
# terraform {
#   backend "consul" {
#     # Backend configuration will be provided during initialization
#     # Can be configured via environment variables:
#     # - CONSUL_HTTP_ADDR
#     # - CONSUL_ACCESS_TOKEN
#     # Or via backend config file during init:
#     # terraform init -backend-config="backend.hcl"
#
#     path = "btd-app/terraform/state"
#     lock = true
#
#     # These can be overridden during initialization
#     # address    = "consul.btd.local:8500"
#     # scheme     = "http"
#     # datacenter = "dc1"
#     # token      = "your-consul-token"
#   }
# }

# Local backend configuration (enabled for initial import)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}