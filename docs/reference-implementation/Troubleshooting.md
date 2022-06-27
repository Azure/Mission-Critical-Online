# Troubleshooting guide

It is inevitable in a system with the complexity of Azure Mission-Critical that issues and errors occur. This living document maintains a list of solutions for common errors, which are not directly caused by the Azure Mission-Critical code (i.e. are outside of control of the development team and cannot be fixed as bugs in the codebase).

- [Deployment issues](#deployment-issues)
  - [Infrastructure Deployment stages](#infrastructure-deployment-stages)
  - [Deploy Workload stage](#deploy-workload-stage)
  - [Testing stages](#testing-stages)
  - [Destroy Infrastructure stage](#destroy-infrastructure-stage)

## Deployment issues

### Infrastructure Deployment stages

**Error:**

```console
A resource with the ID "/subscriptions/[...]/diagnosticSettings/frontdoorladiagnostics" already exists - to be managed via Terraform this resource needs to be imported into the State.
```

**Description:** Occurs on global Terraform apply, specifically `azurerm_monitor_diagnostic_setting.frontdoor`, but it can happen on stamps too (various resources).

This usually happens, when a resource was manually deleted (e.g. through the Azure Portal) instead of running the Destroy step in the pipeline. Some resource types, mostly Diagnostic Settings and Save Queries in Log Analytics Workspaces, are not deleted, when deleting the parent resource. This is a known limitation in ARM.

**Solution:** Go to Azure portal, find the affected parent resource (global Front Door in this case), enter Diagnostic Settings and remove existing settings.

Alternatively, there is a [cleanup script](/src/ops/scripts/Clean-StaleResources.ps1) available, that you can run to bulk-delete stale diagnostics settings or Saved Log Analytics queries.

---
**Error:**

```console
retrieving Diagnostics Categories for Resource "/subscriptions/[...]/frontDoors/afe******-global-fd": insights.DiagnosticSettingsCategoryClient#List: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Network/frontdoors/afe******-global-fd' under resource group 'afe******-global-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix"
```

**Description:** Occurs on global deployment, when Terraform replaces global resources. Specifically on `data.azurerm_monitor_diagnostic_categories.frontdoor`.

**Solution:** Run the failing step again.

---

**Error:**

```console
Sorry, we are currently experiencing high demand in this region, and cannot fulfill your request at this time. The access to the region is currently restricted, to request region access for your subscription, please follow this link https://aka.ms/cosmosdbquota for more details on how to create a region access request.
```

**Description:** When deploying Cosmos DB with zone redundancy it can happen that a region and subscription combination can cause the deployment failure with the error message above. Re-running the pipeline or switching to another region most probably won't help.

**Solution:** As a tactical solution, disable zone redundancy in the geolocation configuration. (`/src/infra/workload/globalresources/cosmosdb.tf` -> `dynamic "geo_location"` -> `"zone_redundant = false"`). Then *manually delete the failed Cosmos DB resource in the portal*. This will likely allow the deployment to succeed.

As disabling zone redundancy is not a recommended solution for a production deployment, you should open an Azure Support Ticket to request quota for zone-redundant deployments for Cosmos DB in your required regions.

---

**Error:**

```console
Provisioning of resource(s) for container service afe******-<region>-aks in resource group afe******-stamp-<region>-rg failed. Message: Operation could not be completed as it results in exceeding approved Total Regional Cores quota.
```

Often times followed by more details about the affected region, the current usage and the additional required quota:

```console
Location: SwedenCentral, Current Limit: 100, Current Usage: 96, Additional Required: 8, (Minimum) New Limit Required: 104. 
```

**Description:** Occurs when a deployment requires more cores than the current quota allows.

**Solution:** Either reduce the number of cores used, request more quota for a given VM SKU size in a given region or switch to another region that provides the required quota. See [regional quota requests](https://docs.microsoft.com/azure/azure-supportability/regional-quota-requests) for more details.

---

**Error:**

```console
Error: deleting Front Door (Subscription: "xxxxx-8cbd-46f2-a146-yyyyyyyyyy"
│ Resource Group Name: "xxxxx-global-rg"
│ Front Door Name: "xxxxx-global-fd"): performing Delete: frontdoors.FrontDoorsClient#Delete: Failure sending request: StatusCode=0 -- Original Error: autorest/azure: Service returned an error. Status=<nil> Code="Conflict" Message="Cannot delete frontend endpoint \"xxxxx.e2e.example.com\" because it is still directly or indirectly (using \"afdverify\" prefix) CNAMEd to front door \"xxxxx-global-fd.azurefd.net\". Please remove the DNS CNAME records and try again."

```

**Description:** *This only happens when you are using custom domain names*. In order to protect customers from DNS-rebinding attacks, by default an Azure Front Door resource cannot be deleted while still a CNAME is pointing to it. However, because of the way Terraform tracks and handles dependencies, there is no direct way to circumvent this.

**Solution:** You can disable the protection by running the following command towards your Azure subscription:

```powershell
az feature register --namespace Microsoft.Network --name BypassCnameCheckForCustomDomainDeletion

# Then you can check the state of it by running:
az feature list -o table --query "[?contains(name, 'Microsoft.Network/BypassCnameCheckForCustomDomainDeletion')].{Name:name,State:properties.state}"

# To de-register the feature again, in case it is not needed/wanted anymore run:
# az feature unregister --namespace Microsoft.Network --name BypassCnameCheckForCustomDomainDeletion
```

Once the feature has been registered (this can take a couple of minutes), deletion should work fine.

### Deploy Workload stage

**Error:**

```console
Deployment of service [HealthService | BackgroundProcessor | CatalogService] failed.
```

**Description:** Rarely the pod deployment in AKS gets stuck for no apparent reason.

**Solution:** Re-run the failing step - there's a high probability that it will work. If not on second run, investigate pod health (look at AKS logs, potential error messages from deployment etc.).

---

**Error:** Deploy CatalogService workload / Install workload CatalogService on AKS clusters failed

```console
certificate for catalogservice-ingress-secret pending.. 
Deployment not ready. Retrying... 1/5
..
Deployment not ready. Retrying... 5/5
##[error]Script failed with exit code: 1
```

**Description:** The "Install workload CatalogService on AKS clusters" step actively monitors the provisioning of a LetsEncrypt certificate for the ingress during the installation of the CatalogService helm chart. If the certificate is not ready, or cannot successfully provisioned this task will fail.

**Solution:** This is most of the time caused by hitting LetsEncrypt thresholds (see [Rate Limits](https://letsencrypt.org/docs/rate-limits/) for more details) for certificate provisioning. You can try to re-run the step, or wait for the certificate to be ready. The following commands can help to investigate the issue further:

```console
# Check certificate status
kubectl get certificates -n workload

# Check certificate request status
kubectl get certificaterequests -n workload

# Check cert-manager logs for more details
kubectl logs deploy/cert-manager -n cert-manager 
```

Relevant log events are for example `cert-manager/certificates-trigger "msg"="Not re-issuing certificate as an attempt has been made in the last hour" "key"="workload/catalogservice-ingress-secret" "retry_delay"=3599055978096`.

To manually force cert-manager to re-request the certificate you can delete the existing one:

```console
# Check certificate status
kubectl get certificates -n workload

# Delete certificate (if in `ready=FALSE` state). This will trigger cert-manager to create a new certificate request
kubectl delete certificate/<certificatename> -n workload
```

### Testing stages

**Error:**

```console
Request to https://.../ failed the max. number of retries.
```

**Description:** This error can happen in the stamp smoke testing step, when the pods are not ready to serve requests for a longer period of time.

**Solution:** Re-run the failing step - there's a high probability that it will work. If not on second run, investigate pod health (look at AKS logs, potential error messages from deployment etc.).

### Destroy Infrastructure stage

**Error:**

```console
Pipeline failed: Script failed with exit code: 1
Destroy Infrastructure • Destroy Old Release Unit Deployment • Fetch previous release prefix through disabled Front Door backends
```

**Description:** This error can happen in the destroy stage of the INT or PROD deployment pipeline, when the pipeline is executed for the very first time. At this point in time, there are not old stamps to be deleted yet. Hence, the error can be ignored.

**Solution:** No action needed. The next time you execute the INT or PROD pipeline, all should work since now a stamp already exists which can then be deleted.

To prevent the error from happening to begin with, you can manually de-select the Destroy stage when starting the pipeline run in Azure DevOps.

---
**Error:**

```console
│ Error: deleting Consumer Group (Subscription: "..."
│ Resource Group Name: "afint3a29-stamp-canadacentral-rg"
│ Namespace Name: "afint3a29-canadacen-evhns"
│ Event Hub Name: "backendqueue-eh"
│ Consumer Group Name: "backendworker-cs"): consumergroups.ConsumerGroupsClient#Delete: Failure sending request: StatusCode=409 -- Original Error: autorest/azure: Service returned an error. Status=<nil> Code="Conflict" Message="Resource Conflict Occurred. Another conflicting operation may be in progress. If this is a retry for failed operation, background clean up is still pending. Try again later. To know more visit https://aka.ms/sbResourceMgrExceptions. . TrackingId:af6b432a-85d8-4797-8c1b-4f3a51dec03b_M7SN1_M7SN1_G4S2, SystemTracker:afint3a29-canadacen-evhns:EventHub:backendqueue-eh, Timestamp:... CorrelationId: ..."
```

**Description:** The deletion of the event hub consumer group as part of the terraform infrastructure destroy process can fail from time to time due to a conflicting operation that happens at the same time.

**Solution:** Re-run the failing step.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
