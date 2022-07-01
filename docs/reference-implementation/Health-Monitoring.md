# Monitoring

- [Monitoring data sources](#monitoring-data-sources)
  - [Diagnostic settings](#diagnostic-settings)
  - [Kubernetes monitoring](#kubernetes-monitoring)
  - [Application Insights Availability Tests](#application-insights-availability-tests)
- [Queries](#queries)
- [Visualization](#visualization)

---

Azure Mission-Critical is using [Azure Log Analytics](https://docs.microsoft.com/azure/azure-monitor/logs/log-analytics-overview) as a central store for logs and metrics for all application and infrastructure components and [Azure Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview) for all application monitoring data. Each stamp has its own, dedicated Log Analytics Workspace and App Insights instance. Next to those is one Log Analytics Workspace for the globally shared resources such as Front Door and Cosmos DB.

![Monitoring overview](/docs/media/MonitoringOverview.png)

As all stamps are short-lived and continuously replaced with each new release (see [Zero-downtime Update Strategy](./DeployAndTest-DevOps-Zero-Downtime-Update-Strategy.md) for more), the per-stamp Log Analytics workspaces are deployed as a global resource in a separate monitoring resource group as the stamp Log Analytics resources, and do not share the lifecycle of a stamp.

## Monitoring data sources

### Diagnostic settings

All Azure services used for Azure Mission-Critical are configured to send all their Diagnostic data including logs and metrics to the deployment specific (global or stamp) Log Analytics Workspace. This happens automatically as part of the [Terraform](/src/infra/README.md#infrastructure) deployment. New options will be identified automatically and added as part of `terraform apply`.

![Diagnostic Settings](/docs/media/Monitoring1DiagnosticSettings.png)

### Kubernetes monitoring

Besides the use of Diagnostic settings to send AKS logs and metrics to Log Analytics, as described above, AKS is also configured to use _Container Insights_. Enabling _Container Insights_ deploys the OMSAgentForLinux via a Kubernetes DaemonSet on each of the nodes in AKS clusters. The OMSAgentForLinux is capable of collecting additional logs and metrics from within the Kubernetes cluster and sends them to its corresponding Log Analytics workspace. This contains more granular data about pods, deployments, services and the overall cluster health.

![AKS Integrations - Container Insights](/docs/media/Monitoring2AKSIntegrations.png)

This also enables a rich monitoring experience within the Azure Portal.

![AKS Container Insights](/docs/media/Monitoring2AKSInsights.png)

To gain even more insights from the various components like ingress-nginx, cert-manager, etc. (see [Configuration layer](/src/config/README.md)) running on top of Kubernetes, next to our workload, it's possible to use [Prometheus scraping](https://docs.microsoft.com/azure/azure-monitor/containers/container-insights-prometheus-integration). This configures the _OMSAgentForLinux_ to scrape Prometheus metrics from various endpoints within the cluster. This is done via a specific ConfigMap stored in `/src/config/monitoring` and provides a variety of additional data points stored in Log Analytics:

```kql
InsightsMetrics
| where Namespace contains "prometheus"
```

![Prometheus metrics](/docs/media/Monitoring2AKSPrometheus.png)

### Application Insights Availability Tests

To monitor the availability of the individual stamps and the overall solution from an outside point of view, [Application Insights Availability Tests](https://docs.microsoft.com/azure/azure-monitor/app/availability-overview) are set up in two places:

- [Regional Availability Tests](/src/infra/workload/releaseunit/modules/stamp/monitoring_webtests.tf): These are set up in the regional Application Insights instances and are used to monitor the availability of the stamps. These tests target the clusters as well as the static storage accounts of the stamps directly. To call the ingress points of the clusters directly, requests need to carry the correct Front Door ID header, else they would be rejected by the ingress controller.
- [Global Availability Tests](/src/infra/workload/globalresources/monitoring_webtests.tf): These are set up in the global Application Insights instance and are used to monitor the availability of the overall solution by pinging Front Door. Here as well, two tests are being used: One to test an API call against the CatalogService and one to test the home page of the website.

## Queries

Azure Mission-Critical uses different Kusto Query Language (KQL) queries to implement complex, custom queries as functions to retrieve data from Log Analytics. These queries are stored as individual files in the `/src/infra/monitoring/queries` directory (separated into global and stamp) and are imported and applied automatically via Terraform as part of each infrastructure pipeline run.

This approach separates the query logic from the visualization layer. It allows us to call these functions individually and use them either directly to retrieve data from Log Analytics or to visualize the results in Azure Dashboards, Azure Monitor Workbooks or 3rd-Party dashboarding solutions like Grafana.

Here's an example - the `AksClusterHealthStatus()` ([see the .kql file for details](/src/infra/monitoring/queries/stamp/AksClusterHealthScore.kql)) query retrieves some key metrics per cluster and decides based on given thresholds if the status is "yellow" or "red":

![LogAnalytics Query](/docs/media/Monitoring3.png)

This result provides a granular overview about the cluster's health status based on the given metrics and thresholds. To sum this up and to get a more high-level overview per cluster, `AksClusterHealthScore()` can be used:

![LogAnalytics Query AksClusterHealthScore](/docs/media/Monitoring4.png)

## Visualization

The Visualization of the Kusto [Queries](#Queries) described above was implemented using Grafana. Grafana is used to show the results of Log Analytics queries and does not contain any logic itself. The Grafana stack is not part of the solution's deployment lifecycle, but released separately. For a detailed description of the Grafana deployment for Azure Mission-Critical, please refer to the [Grafana README](/src/infra/monitoring/grafana/README.md).

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
