# Alerting

Alerts are an important part of the operations strategy. While there should also be more proactive means of monitoring, for example dashboards, alerts raise immediate attention to issues.

While most critical alert rules should be defined during the building of an application, rules will always require refinement over time. Outages caused by errors that went undetected, often lead to the creation of additional monitoring point and alert rules.
Alerts could be delivered as emails, mobile push notifications, tickets created in an IT Service Management system etc. The important part is that they get routed to a place where they will be noticed and acted upon quickly.

A full definition and implementation of alert rules would go beyond the scope of the reference implementation. Thus, only a couple of examples are implemented. In the reference implementation we only use email notifications but other alert sinks can also be configured using Terraform. To avoid unnecessary noise, alerts are not created in the E2E environments.

Alerts in Azure can be configured at various levels. For each category we define a couple of sample alerts which we consider most valuable. Not all of the samples are actually implemented in the reference implementation, but other alerts can follow the same route.

## Azure Resource-level alerts

Resource-level alerts are configured on an Azure resource itself. It is therefore scoped to only that resource and does not correlate with signals from other resources.

### Activity Log Alerts

#### Valuable alerts

-

### Metric Alerts

Metric alerts are limited to the built-in metrics that Azure provides for a given resource.

#### Valuable alerts

- Front Door - Backend Health dropping under threshold
- Cosmos DB - Availability dropping under threshold
- Cosmos DB - RU consumption percentage reaching a threshold
- Event Hub Namespace - Quota Exceeded Errors (or Throttled Requests) greater than 0
- Event Hub Namespace - Outgoing messages dropping to 0
- Key Vault - Overall Vault Availability dropping under threshold
- AKS - Unschedulable pods greater than 0 for sustained period
- Storage Account - Availability dropping under threshold

#### Front Door - Backend Health

> This alert is implemented as a sample as part of the reference implementation.

A metric alert is configured as part of the infrastructure deployment on Front Door (/src/infra/workload/alerts.tf). We are using the "Backend Health Percentage" metric to create an alert when any one backend's health, as detected by Front Door, falls under a certain threshold in the last minute.

![Backend Health Metric](/docs/media/monitoring-fd-backend-health.png)

Many causes for the backend health to drop should also be detected on other levels (and potentially earlier). For instance, anything that causes the Health Service to report "unhealthy" to Front Door's health probes should also be logged to Application Insights. Similarly, issues on the static storage accounts should also be detected through the collected diagnostic logs. However, there can still be outages which are not showing up in other signals.

Front Door does not provide any further insight into why the backend health for a certain backend drops. Therefore, we also implemented [URL Ping tests](https://docs.microsoft.com/azure/azure-monitor/app/monitor-web-app-availability) in each stamp's Application Insights resource ([/src/infra/workload/releaseunit/modules/stamp/monitoring.tf](/src/infra/workload/releaseunit/modules/stamp/monitoring.tf)). This calls the same URL of the cluster HealthService (as well as checking the static website storage account) as Front Door does and provides detailed logging and tracing. We can use this to help us determine the cause for an outage: Was the cluster reachable at all? Is the Ingress Controller routing the request correctly? Did the HealthService respond with a 503 response?

![Application Insights URL Ping test](/docs/media/monitoring-appi-url-pingtest.png)

## Log Analytics / Application Insights query-based alerts

Alerts based on the data stored in a Log Analytics workspace can be created using any arbitrary query. Therefore they are well-suited for correlation of events from multiple sources. Also, they can be used to create alerts based on application-level signals as opposed to only resource-level events and metrics.

#### Valuable alerts

- Percentage of 5xx responses / failed requests exceeding a threshold
- The result of the ClusterHealthScore() function dropping below 1
- Spike in entries in the Exception table (not all errors are correlated to incoming requests so they won't be covered by the previous alert, for instance exceptions in the BackgroundProcessor)

#### Percentage of 5xx responses / failed requests exceeding a threshold

> This alert is implemented as a sample as part of the reference implementation.

To demonstrate their setup and usage, a query-based alert on Application Insights is configured as part of the infrastructure deployment within each stamp ([/src/infra/workload/releaseunit/modules/stamp/alerts.tf](/src/infra/workload/releaseunit/modules/stamp/alerts.tf)). It looks at the number of responses sent by the CatalogService which start with a 5xx status code. If those exceed the set threshold within a 5 minute window, it will fire an alert.
