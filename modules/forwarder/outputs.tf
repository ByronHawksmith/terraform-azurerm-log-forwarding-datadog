# ==========================================
# Storage Account Outputs
# ==========================================

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.forwarder_storage.name
}

output "storage_account_id" {
  description = "ID of the created storage account"
  value       = azurerm_storage_account.forwarder_storage.id
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.forwarder_storage.primary_access_key
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.forwarder_storage.primary_blob_endpoint
}

# ==========================================
# Container App Environment Outputs
# ==========================================

output "container_app_environment_id" {
  description = "ID of the container app environment"
  value       = azurerm_container_app_environment.forwarder_env.id
}

output "container_app_environment_name" {
  description = "Name of the container app environment"
  value       = azurerm_container_app_environment.forwarder_env.name
}

# ==========================================
# Container App Job Outputs
# ==========================================

output "container_app_job_id" {
  description = "ID of the container app job"
  value       = azurerm_container_app_job.forwarder.id
}

output "container_app_job_name" {
  description = "Name of the container app job"
  value       = azurerm_container_app_job.forwarder.name
}
