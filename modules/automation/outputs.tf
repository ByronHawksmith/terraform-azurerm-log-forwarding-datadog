# Essential Outputs

output "control_plane_id" {
  description = "The control plane identifier used for resource naming"
  value       = local.control_plane_id
}

output "resource_group_name" {
  description = "Name of the automation resource group"
  value       = azurerm_resource_group.resource_group.name
}

output "resources_task_principal_id" {
  description = "Managed identity principal ID of the resources task function app (for additional role assignments)"
  value       = azurerm_linux_function_app.resources_task.identity[0].principal_id
}

output "scaling_task_principal_id" {
  description = "Managed identity principal ID of the scaling task function app (for additional role assignments)"
  value       = azurerm_linux_function_app.scaling_task.identity[0].principal_id
}

output "diagnostic_settings_task_principal_id" {
  description = "Managed identity principal ID of the diagnostic settings task function app (for additional role assignments)"
  value       = azurerm_linux_function_app.diagnostic_settings_task.identity[0].principal_id
}
