# Troubleshooting guide

It's inevitable in a system with the complexity of AlwaysOn that issues and errors occur. This living document maintains a list of solutions for common errors, which are not directly caused by the AlwaysOn code (i.e. are outside of control of the development team and cannot be fixed as bugs in the codebase).

## Deployment issues

### Infrastructure Deployment stages

**Error:**
```
A resource with the ID "/subscriptions/[...]/diagnosticSettings/frontdoorladiagnostics" already exists - to be managed via Terraform this resource needs to be imported into the State.
```


**Description:** Occurs on global Terraform apply, specifically azurerm_monitor_diagnostic_setting.frontdoor, but it can happen on stamps too (various resources).

This usually happens, when a resource was manually deleted (e.g. through the Azure Portal) instead of running the Destroy step in the pipeline. Some resource types, mostly Diagnostic Settings and Save Queries in Log Analytics Workspaces, are not deleted, when deleting the parent resource. This is a known limitation in ARM.

**Solution:** Go to Azure portal, find the affected parent resource (global Front Door in this case), enter Diagnostic Settings and remove existing settings.

Alternatively, there is a [cleanup script](/src/ops/scripts/Clean-StaleResources.ps1) available, that you can run to bulk-delete stale diagnostics settings or Saved Log Analytics queries.

---
**Error:**

```
retrieving Diagnostics Categories for Resource "/subscriptions/[...]/frontDoors/afe2ece5c-global-fd": insights.DiagnosticSettingsCategoryClient#List: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Network/frontdoors/afe2ece5c-global-fd' under resource group 'afe2ece5c-global-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix"
```

**Description:** Occurs on global deployment, when Terraform replaces global resources. Specifically on `data.azurerm_monitor_diagnostic_categories.frontdoor`.

**Solution:** Run the failing step again.

---
**Error:**

```
Sorry, we are currently experiencing high demand in this region, and cannot fulfill your request at this time. The access to the region is currently restricted, to request region access for your subscription, please follow this link https://aka.ms/cosmosdbquota for more details on how to create a region access request.
```

**Description:** When deploying CosmosDB with zone redundancy it can happen that a region and subscription combination can cause the deployment failure with the error message above. Re-running the pipeline or switching to another region most probably won't help.

**Solution:** Disable zone redundancy in the geolocation configuration. (`/src/infra/cosmosdb.tf` -> `dynamic "geo_location"` -> `"zone_redundant = false"`).

### Deploy Workload stage

**Error:**
```
Deployment of service [HealthService | BackgroundProcessor | CatalogService] failed.
```

**Description:** Rarely the pod deployment in AKS gets stuck for no apparent reason.

**Solution:** Re-run the failing step - there's a high probability that it will work. If not on second run, investigate pod health (look at AKS logs, potential error messages from deployment etc.).


### Testing stages

**Error:**
```
Request to https://.../ failed the max. number of retries.
```

**Description:** This error can happen in the stamp smoke testing step, when the pods are not ready to serve requests for a longer period of time.

**Solution:** Re-run the failing step - there's a high probability that it will work. If not on second run, investigate pod health (look at AKS logs, potential error messages from deployment etc.).

### Destroy Infrastructure stage

**Error:**
```
Pipeline failed: Script failed with exit code: 1
Destroy Infrastructure • Destroy Old Release Unit Deployment • Fetch previous release prefix through disabled Front Door backends
```

**Description:** This error can happen in the destroy stage of the INT or PROD deployment pipeline, when the pipeline is executed for the very first time. At this point in time, there are not old stamps to be deleted yet. Hence, the error can be ignored.

**Solution:** No action needed. The next time you execute the INT or PROD pipeline, all should work since now a stamp already exists which can then be deleted.

To prevent the error from happening to begin with, you can manually de-select the Destroy stage when starting the pipeline run in Azure DevOps.