# Terraform Modules for Datadog Azure Log Forwarding

Terraform modules for deploying [Datadog Automated Log Forwarding for Azure](https://github.com/DataDog/azure-log-forwarding-orchestration) to your Azure environment.

These modules handle the infrastructure provisioning side of log forwarding. It creates the resource groups, storage accounts, container app environments, and function apps that run the orchestration system.

## What This Does

The [Automated Log Forwarding for Azure](https://github.com/DataDog/azure-log-forwarding-orchestration) system automatically discovers Azure resources, configures diagnostic settings, and forwards logs to Datadog. It scales dynamically based on actual log volume and requires minimal ongoing maintenance.

This Terraform repository provides two deployment approaches:

| Module | Description | Best For |
|--------|-------------|----------|
| [`automation`](./modules/automation) | Full control plane with automatic resource discovery, diagnostic settings configuration, and dynamic scaling | Multi-subscription deployments, hands-off operation |
| [`forwarder`](./modules/forwarder) | Standalone log forwarder without the orchestration layer | Single subscription, manual diagnostic settings, simpler setup |

There's also [`automated-resource-group`](./modules/automated-resource-group) for creating resource groups in additional subscriptions when using the automation module across multiple subscriptions.

## Prerequisites

- Terraform >= 1.0
- Azure subscription with Contributor access
- AzureRM provider ~> 4.0
- Datadog account and [API key](https://docs.datadoghq.com/account_management/api-app-keys/)

## Quick Start

### Full Automation (Recommended)

Deploy the complete orchestration system that automatically discovers resources and configures log forwarding:

```hcl
provider "azurerm" {
  features {}
}

module "automation" {
  source  = "DataDog/log-forwarding-datadog/azurerm//modules/automation"

  resource_group_name = "rg-datadog-log-forwarding"
  location            = "East US"

  datadog_api_key = var.datadog_api_key
  datadog_site    = "datadoghq.com"  # or us3, us5, eu, etc.

  # Optional: filter which resources to monitor
  resource_tag_filters = "env:prod,!temporary:true"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Standalone Forwarder

For simpler deployments where you manage diagnostic settings yourself:

```hcl
provider "azurerm" {
  features {}
}

module "forwarder" {
  source  = "DataDog/log-forwarding-datadog/azurerm//modules/forwarder"

  resource_group_name  = "rg-datadog-forwarder"
  location             = "East US"
  storage_account_name = "yourlogstorage123"  # must be globally unique

  datadog_api_key = var.datadog_api_key
  datadog_site    = "datadoghq.com"

  tags = {
    Environment = "production"
  }
}
```

Then configure Azure diagnostic settings to send logs to the storage account.

## Multi-Subscription Setup

The automation module can monitor resources across multiple Azure subscriptions. Each monitored subscription needs a resource group (with the same name) where forwarders will be deployed:

```hcl
locals {
  resource_group_name = "rg-datadog-log-forwarding"
}

# Create resource group in additional subscription
module "monitored_rg" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automated-resource-group"
  providers = {
    azurerm = azurerm.monitored_subscription
  }

  resource_group_name = local.resource_group_name
  location            = "East US"
}

# Deploy automation with cross-subscription access
module "automation" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automation"

  resource_group_name = local.resource_group_name
  location            = "East US"

  datadog_api_key = var.datadog_api_key
  datadog_site    = "datadoghq.com"

  monitored_resource_groups = {
    (module.monitored_rg.subscription_id) = {
      subscription_id     = module.monitored_rg.subscription_id
      resource_group_name = module.monitored_rg.resource_group_name
    }
  }
}
```

## Module Documentation

Each module has its own README with detailed configuration options:

- [modules/automation](./modules/automation) - Full orchestration control plane
- [modules/forwarder](./modules/forwarder) - Standalone log forwarder
- [modules/automated-resource-group](./modules/automated-resource-group) - Resource group for multi-subscription setups

## Related Projects

- [Automated Log Forwarding for Azure](https://github.com/DataDog/azure-log-forwarding-orchestration) - The orchestration system these modules deploy
- [Datadog Azure Integration](https://docs.datadoghq.com/integrations/azure/) - Native Azure monitoring integration

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.