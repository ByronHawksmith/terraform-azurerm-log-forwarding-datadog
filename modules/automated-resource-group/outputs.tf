# Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2 License.

# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2025 Datadog, Inc.

output "resource_group_id" {
  description = "The ID of the created resource group"
  value       = azurerm_resource_group.resource_group.id
}

output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.resource_group.name
}

output "resource_group_location" {
  description = "The location of the created resource group"
  value       = azurerm_resource_group.resource_group.location
}

output "subscription_id" {
  description = "The subscription ID where the resource group was created"
  value       = data.azurerm_client_config.current.subscription_id
}
