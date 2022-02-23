# Troubleshooting guide

It's inevitable in a system with the complexity of AlwaysOn that issues and errors occur. This living document maintains a list of solutions for common errors, which are not directly caused by the AlwaysOn code (i.e. are outside of control of the development team and cannot be fixed as bugs in the codebase).

## Deployment issues

### A resource with the ID "/subscriptions/[...]/diagnosticSettings/frontdoorladiagnostics" already exists - to be managed via Terraform this resource needs to be imported into the State.

**Description:** Occurs on global Terraform apply, specifically azurerm_monitor_diagnostic_setting.frontdoor, but it can happen on stamps too (various resources).

**Solution:** Go to Azure portal, find the affected parent resource (global Front Door in this case), enter Diagnostic Settings and remove existing settings.

---

### retrieving Diagnostics Categories for Resource "/subscriptions/[...]/frontDoors/afe2ece5c-global-fd": insights.DiagnosticSettingsCategoryClient#List: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Network/frontdoors/afe2ece5c-global-fd' under resource group 'afe2ece5c-global-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix"

**Description:** Occurs on global deployment, when Terraform replaces global resources. Specifically on `data.azurerm_monitor_diagnostic_categories.frontdoor`.

**Solution:** Run the failing step again. 

---

### Sorry, we are currently experiencing high demand in this region, and cannot fulfill your request at this time. The access to the region is currently restricted, to request region access for your subscription, please follow this link\u00a0https://aka.ms/cosmosdbquota for more details on how to create a region access request.

**Description:** When deploying CosmosDB with zone redundancy it can happen that a region and subscription combination can cause the deployment failure with the error message above. Re-running the pipeline or switching to another region most probably won't help.

**Solution:** Disable zone redundancy in the geolocation configuration. (`/src/infra/cosmosdb.tf` -> `dynamic "geo_location"` -> `"zone_redundant = false"`).

---

### Request to https://.../ failed the max. number of retries.

**Description:** This error can happen in the stamp smoke testing step, when the pods are not ready to serve requests for a longer period of time.

**Solution:** Re-run the failing step - there's a high probability that it will work. If not on second run, investigate pod health (look at AKS logs, potential error messages from deployment etc.).
