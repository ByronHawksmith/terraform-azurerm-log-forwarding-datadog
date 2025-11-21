# Datadog Log Forwarder Module

This Terraform module deploys a standalone Datadog log forwarder using Azure Container Apps Jobs. It provides a simple, cost-effective way to forward Azure logs stored in blob storage to Datadog.

## Use Case

Use this module when you want to:
- Forward logs from Azure to Datadog without complex infrastructure
- Maintain control over resource sizing and scheduling
- Deploy log forwarding in a single subscription
- Keep your infrastructure simple and maintainable

For automated multi-subscription deployments, consider the `automation` module instead.

## Architecture

The module creates:
- **Storage Account**: Stores logs before forwarding to Datadog
- **Container App Environment**: Hosts the Container App Job
- **Container App Job**: Scheduled job that forwards logs to Datadog
- **Lifecycle Policy**: Automatically deletes old logs after retention period

## Key Features

- **Cost Optimized**: Uses Consumption plan - pay only for execution time
- **Configurable Resources**: Adjust CPU, memory, timeout, and retry settings
- **Automatic Cleanup**: Lifecycle management prevents storage bloat
- **Secure by Default**: HTTPS-only, TLS 1.2 minimum, secrets stored securely
- **Flexible Scheduling**: Configure job frequency with cron expressions

## Quick Start

```hcl
module "forwarder" {
  source = "path/to/modules/forwarder"

  resource_group_name  = "rg-datadog-forwarder"
  location             = "East US"
  storage_account_name = "myuniquelogstore123"

  datadog_api_key = var.datadog_api_key
  datadog_site    = "datadoghq.com"

  tags = {
    Environment = "production"
  }
}
```

## Resource Sizing Guide

### Default Configuration (Medium Volume)
- **CPU**: 2 cores
- **Memory**: 4Gi
- **Use case**: Typical production workloads

### Small Volume
```hcl
forwarder_cpu    = 0.5
forwarder_memory = "1Gi"
```

### High Volume
```hcl
forwarder_cpu              = 2.0
forwarder_memory           = "4Gi"
replica_timeout_in_seconds = 1800  # Full 30 minutes
```

## Scheduling Examples

```hcl
# Every minute (default - for real-time forwarding)
schedule_expression = "* * * * *"

# Every 5 minutes (reduced cost)
schedule_expression = "*/5 * * * *"

# Every hour (batch processing)
schedule_expression = "0 * * * *"
```

## Storage Configuration

### Cost Optimization
```hcl
storage_account_sku            = "Standard_LRS"  # Most cost-effective
storage_account_retention_days = 1              # Minimum retention
storage_access_tier            = "Hot"          # For frequent access
```

### High Availability
```hcl
storage_account_sku            = "Standard_GRS"  # Geo-redundant
storage_account_retention_days = 7              # Longer retention
```

## Requirements

- Azure subscription with Contributor access
- Existing resource group
- Datadog account with API key
- Globally unique storage account name

## Limitations

- Consumption plan limited to 2 CPU cores and 4Gi memory
- Maximum replica timeout is 30 minutes (1800 seconds)
- Storage account names must be globally unique across Azure

## Next Steps

After deploying:
1. Configure Azure diagnostic settings to write logs to the storage account
2. Monitor job execution in Azure Portal or with Azure CLI
3. View forwarded logs in your Datadog account
4. Adjust resource sizing based on actual log volume

See the [examples/forwarder](../../examples/forwarder) directory for a complete example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app_environment.forwarder_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_job.forwarder](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_storage_account.forwarder_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_management_policy.forwarder_lifecycle](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API Key for authentication.<br/>Must be exactly 32 characters long.<br/>This is stored as a secret in the Container App Job. | `string` | n/a | yes |
| <a name="input_datadog_site"></a> [datadog\_site](#input\_datadog\_site) | Datadog Site to send logs to.<br/>Must be one of the official Datadog sites. | `string` | `"datadoghq.com"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Name of the Container App Managed Environment for the Forwarder.<br/>Must be between 2 and 60 characters long. | `string` | `"datadog-log-forwarder-env"` | no |
| <a name="input_forwarder_cpu"></a> [forwarder\_cpu](#input\_forwarder\_cpu) | CPU allocation for the forwarder container in cores.<br/>Valid values: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0<br/>Note: Consumption plan environments are limited to 2.0 CPU maximum. | `number` | `2` | no |
| <a name="input_forwarder_image"></a> [forwarder\_image](#input\_forwarder\_image) | Container image for the forwarder.<br/>Example: "datadoghq.azurecr.io/forwarder:latest" | `string` | `"datadoghq.azurecr.io/forwarder:latest"` | no |
| <a name="input_forwarder_memory"></a> [forwarder\_memory](#input\_forwarder\_memory) | Memory allocation for the forwarder container.<br/>Must be in the format of a number followed by 'Gi' (e.g., "0.5Gi", "1Gi", "2Gi", "4Gi").<br/>Note: Consumption plan environments are limited to 4Gi maximum. | `string` | `"4Gi"` | no |
| <a name="input_job_name"></a> [job\_name](#input\_job\_name) | Name of the Forwarder Container App Job.<br/>Must be between 1 and 260 characters long. | `string` | `"datadog-log-forwarder"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created.<br/>Example: "East US", "West Europe", "Southeast Asia" | `string` | `"East US"` | no |
| <a name="input_replica_retry_limit"></a> [replica\_retry\_limit](#input\_replica\_retry\_limit) | Number of times to retry a failed replica.<br/>Must be between 0 and 10.<br/>A value of 0 means no retries, 1 means retry once, etc. | `number` | `1` | no |
| <a name="input_replica_timeout_in_seconds"></a> [replica\_timeout\_in\_seconds](#input\_replica\_timeout\_in\_seconds) | Maximum number of seconds a replica is allowed to run.<br/>Must be between 60 and 1800 seconds (1 minute to 30 minutes).<br/>This timeout determines how long the forwarder job can run before being terminated. | `number` | `1800` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where resources will be created.<br/>This resource group must already exist. | `string` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Cron expression for the forwarder job schedule.<br/>Uses standard cron format (minute hour day month weekday).<br/>Examples:<br/>  - "* * * * *" (every minute)<br/>  - "*/5 * * * *" (every 5 minutes)<br/>  - "0 * * * *" (every hour) | `string` | `"* * * * *"` | no |
| <a name="input_storage_access_tier"></a> [storage\_access\_tier](#input\_storage\_access\_tier) | Access tier for the storage account.<br/>- "Hot": Optimized for frequent access (higher storage cost, lower access cost)<br/>- "Cool": Optimized for infrequent access (lower storage cost, higher access cost)<br/>For log forwarding with short retention periods, "Hot" is typically appropriate. | `string` | `"Hot"` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the Log Storage Account.<br/>Must be between 3 and 24 characters long.<br/>Must be lowercase letters and numbers only.<br/>Must be globally unique across Azure. | `string` | `"datadoglogstorage"` | no |
| <a name="input_storage_account_retention_days"></a> [storage\_account\_retention\_days](#input\_storage\_account\_retention\_days) | The number of days to retain logs in the storage account before automatic deletion.<br/>Must be at least 1 day.<br/>Lower values reduce storage costs but provide less time to recover from issues. | `number` | `1` | no |
| <a name="input_storage_account_sku"></a> [storage\_account\_sku](#input\_storage\_account\_sku) | The SKU of the storage account.<br/>Format: {Tier}\_{Replication}<br/>- Premium tier supports LRS and ZRS only<br/>- Standard tier supports LRS, GRS, GZRS, and ZRS<br/>For log forwarding, Standard\_LRS is typically sufficient and most cost-effective. | `string` | `"Standard_LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources.<br/>Example: { Environment = "production", ManagedBy = "terraform" } | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_environment_id"></a> [container\_app\_environment\_id](#output\_container\_app\_environment\_id) | ID of the container app environment |
| <a name="output_container_app_environment_name"></a> [container\_app\_environment\_name](#output\_container\_app\_environment\_name) | Name of the container app environment |
| <a name="output_container_app_job_id"></a> [container\_app\_job\_id](#output\_container\_app\_job\_id) | ID of the container app job |
| <a name="output_container_app_job_name"></a> [container\_app\_job\_name](#output\_container\_app\_job\_name) | Name of the container app job |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | ID of the created storage account |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the created storage account |
| <a name="output_storage_account_primary_access_key"></a> [storage\_account\_primary\_access\_key](#output\_storage\_account\_primary\_access\_key) | Primary access key of the storage account |
| <a name="output_storage_account_primary_blob_endpoint"></a> [storage\_account\_primary\_blob\_endpoint](#output\_storage\_account\_primary\_blob\_endpoint) | Primary blob endpoint of the storage account |
<!-- END_TF_DOCS -->
