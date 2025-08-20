# Datadog Azure Log Forwarding Automation
Use this Terraform module to deploy a resource group to be used for forwarding logs from Azure to Datadog.


## Usage

```hcl
module "log_automation" {
  source = "DataDog/log-automation-datadog/azurerm//modules/automation"

  control_plane       = true
  location            = "East US"
  resource_group_name = "my-awesome-resource-group"

}
```