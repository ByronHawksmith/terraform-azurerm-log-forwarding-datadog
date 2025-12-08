# Datadog Log Forwarder Example

This example demonstrates how to deploy the Datadog log forwarder as a standalone Container App Job. This is the simplest deployment model for forwarding Azure logs to Datadog.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│               Azure Resource Group                       │
│                                                          │
│  ┌─────────────────┐        ┌────────────────────────┐   │
│  │ Storage Account │        │ Container App Job      │   │
│  │                 │        │                        │   │
│  │  • Log storage  │◀───────│  • Datadog Forwarder   │   │
│  │  • Retention:   │        │  • Scheduled (cron)    │   │
│  │    1 day default│        │  • CPU: 2 cores        │   │
│  │                 │        │  • Memory: 4Gi         │   │
│  │                 │        │                        │   │
│  └─────────────────┘        └────────────────────────┘   │
│                                       │                  │
│                                       │ (Forwards to)    │
│                                       ▼                  │
│                             ┌──────────────────┐         │
│                             │   Datadog API    │         │
│                             └──────────────────┘         │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## How It Works

1. **Log Storage**: Azure diagnostic settings or other sources write logs to the storage account
2. **Scheduled Execution**: The Container App Job runs on a cron schedule (default: every minute)
3. **Log Forwarding**: The job reads logs from storage and forwards them to Datadog
4. **Automatic Cleanup**: Storage lifecycle policy deletes logs older than the retention period

## Prerequisites

- An existing Azure subscription
- An existing Azure resource group
- A Datadog account with an API key
- Terraform >= 1.0 installed
- Azure CLI authenticated (`az login`)

## Quick Start

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your values:
   - `resource_group_name`: Your existing resource group name
   - `location`: Your preferred Azure region
   - `storage_account_name`: A globally unique name (3-24 lowercase alphanumeric characters)
   - `datadog_api_key`: Your 32-character Datadog API key
   - `datadog_site`: Your Datadog site (e.g., `datadoghq.com`, `datadoghq.eu`)

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Deploy**:
   ```bash
   terraform apply
   ```

## Customization Options

### Reduce Resource Costs

For lower-volume workloads, you can reduce CPU and memory allocation:

```hcl
module "forwarder" {
  # ... other configuration ...

  forwarder_cpu    = 1.0   # Reduce to 1 core
  forwarder_memory = "2Gi" # Reduce to 2Gi
}
```

### Adjust Execution Schedule

Change how often the forwarder runs:

```hcl
module "forwarder" {
  # ... other configuration ...

  # Run every 5 minutes instead of every minute
  schedule_expression = "*/5 * * * *"

  # Run every hour at minute 0
  # schedule_expression = "0 * * * *"
}
```

### Increase Storage Retention

Keep logs longer before automatic deletion:

```hcl
module "forwarder" {
  # ... other configuration ...

  storage_account_retention_days = 7  # Keep logs for 7 days
}
```

### Adjust Execution Timeout

For larger log volumes that take longer to process:

```hcl
module "forwarder" {
  # ... other configuration ...

  replica_timeout_in_seconds = 1800  # 30 minutes (maximum)
}
```

## Outputs

After deployment, Terraform outputs key information:

- `storage_account_name`: The name of your storage account (needed for configuring diagnostic settings)
- `storage_account_id`: The full Azure resource ID of the storage account
- `container_app_job_name`: The name of the Container App Job

## Monitoring

### View Job Execution History

```bash
# Get the job name from Terraform output
JOB_NAME=$(terraform output -raw container_app_job_name)
RESOURCE_GROUP="your-resource-group-name"

# List recent job executions
az containerapp job execution list \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --output table
```

### View Job Logs

```bash
# Get logs for the most recent execution
az containerapp job logs show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP
```

## Configuring Diagnostic Settings

After deploying the forwarder, configure your Azure resources to send logs to the storage account:

```bash
STORAGE_ACCOUNT_ID=$(terraform output -raw storage_account_id)

# Example: Forward Activity Logs
az monitor diagnostic-settings create \
  --name "datadog-activity-logs" \
  --resource "/subscriptions/{subscription-id}" \
  --storage-account $STORAGE_ACCOUNT_ID \
  --logs '[{"category":"Administrative","enabled":true}]'
```

## Cost Optimization

The default configuration is designed for small to medium log volumes:

- **Consumption plan**: Pay only for job execution time
- **Standard_LRS storage**: Locally redundant, most cost-effective
- **1-day retention**: Minimize storage costs
- **Hot access tier**: Optimized for frequent access during forwarding

For high-volume scenarios, consider:
- Reducing CPU/memory if logs forward quickly
- Increasing schedule interval (run less frequently)
- Using Cool access tier if logs are written infrequently

## Troubleshooting

### Job Not Running

Check the Container App Job status:
```bash
az containerapp job show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "properties.configuration.triggerType"
```

### Logs Not Forwarding

1. Check job execution logs for errors
2. Verify Datadog API key is correct (32 characters)
3. Verify Datadog site is correct for your region
4. Check storage account has logs to forward

### Storage Account Name Conflicts

Storage account names must be globally unique. If you get a naming conflict error, change `storage_account_name` to a different value.

## Clean Up

To remove all resources:

```bash
terraform destroy
```

Note: This will delete the storage account and any logs it contains. Make sure logs have been forwarded to Datadog before destroying.

## Security Considerations

- **API Key Storage**: The Datadog API key is stored as a secret in the Container App Job and never appears in logs or outputs
- **Storage Access**: The storage account is configured with HTTPS-only access and TLS 1.2 minimum
- **Network Access**: By default, resources are publicly accessible. For production, consider adding network restrictions

## Next Steps

- Configure diagnostic settings on your Azure resources to send logs to the storage account
- Monitor job execution in the Azure Portal
- View forwarded logs in your Datadog account
- Adjust resource sizing based on your log volume

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_forwarder"></a> [forwarder](#module\_forwarder) | ../../modules/forwarder | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API Key (32 characters) | `string` | n/a | yes |
| <a name="input_datadog_site"></a> [datadog\_site](#input\_datadog\_site) | Datadog Site (e.g., datadoghq.com, datadoghq.eu) | `string` | `"datadoghq.com"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group where resources will be created | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric characters) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_job_name"></a> [container\_app\_job\_name](#output\_container\_app\_job\_name) | Name of the container app job |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | ID of the created storage account |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the created storage account |
<!-- END_TF_DOCS -->
