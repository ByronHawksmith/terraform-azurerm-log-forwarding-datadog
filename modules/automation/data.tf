# Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2 License.

# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2025 Datadog, Inc.

# Data sources for current Azure context
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}
