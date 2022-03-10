# Operational Scripts

This folder contains scripts that are used to perform various operational tasks on the reference implementation.

- [Clean-StaleResources.ps1](./Clean-StaleResources.ps1). This script contains functions to clean up left over resources from previous deployments that are known to cause problems with new Terraform deployments, mostly when resources have been manually removed (e.g. through the Azure Portal):
  - `Remove-SavedLogAnalyticsQueries` - Removes all saved queries from the Log Analytics workspaces. These resources are not immediately deleted if a Log Analytics workspace is deleted. If a workspace with the same name gets created again, those stale saved queries will be re-attached automatically. This causes conflicts with Terraform.
  - `Remove-DiagnosticSettings` - Removes all diagnostic settings on resources for a given deployment (i.e. prefix). These are not immediately deleted if a resource is deleted manually. If a resource with the same name gets created again, those stale resources will be re-attached automatically. This causes conflicts with Terraform.

- Clean up Terraform state storage accounts (remove stale state files): [Clean-TerraformState.ps1](./Clean-TerraformState.ps1). This is only needed if you want to clean up stale state files from previous deployments. Should not be required regularly, since Terraform will just re-use old state files, even if they are out of date.

To run either of the scripts, "dot-source" the script and then run the script:

```powershell
  . "./Clean-StaleResources.ps1"

  Remove-DiagnosticSettings -ResourcePrefix "aoe2e123"
```
