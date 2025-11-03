# Outputs for Infrastructure Module

output "redis" {
  description = "Redis container details"
  value = {
    id         = module.infrastructure_containers["redis"].container_id
    ip_address = module.infrastructure_containers["redis"].ip_address
  }
}

output "postgres" {
  description = "PostgreSQL container details"
  value = {
    id         = module.infrastructure_containers["postgres"].container_id
    ip_address = module.infrastructure_containers["postgres"].ip_address
  }
}

output "consul" {
  description = "Consul container details"
  value = {
    id         = module.infrastructure_containers["consul"].container_id
    ip_address = module.infrastructure_containers["consul"].ip_address
  }
}

output "minio" {
  description = "MinIO container details"
  value = {
    id         = module.infrastructure_containers["minio"].container_id
    ip_address = module.infrastructure_containers["minio"].ip_address
  }
}

output "rabbitmq" {
  description = "RabbitMQ container details"
  value = {
    id         = module.infrastructure_containers["rabbitmq"].container_id
    ip_address = module.infrastructure_containers["rabbitmq"].ip_address
  }
}

output "monitoring" {
  description = "Monitoring container details"
  value = {
    id         = module.infrastructure_containers["monitoring"].container_id
    ip_address = module.infrastructure_containers["monitoring"].ip_address
  }
}

output "all_containers" {
  description = "All infrastructure container details"
  value = {
    for key, container in module.infrastructure_containers : key => {
      id         = container.container_id
      ip_address = container.ip_address
    }
  }
}