# Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2 License.

# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2025 Datadog, Inc.

# Data sources for current Azure context
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# Built-in Azure role definitions for function app permissions
# These role IDs are consistent across all Azure tenants

data "azurerm_role_definition" "monitoring_reader" {
  name  = "Monitoring Reader"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "monitoring_contributor" {
  name  = "Monitoring Contributor"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "reader_data_access" {
  name  = "Reader and Data Access"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "website_contributor" {
  name  = "Website Contributor"
  scope = data.azurerm_subscription.current.id
}
