# Business Continuity/Disaster Recovery

## Introduction

The Azure Mission-Critical architecture is based on the [deployment stamp pattern](https://learn.microsoft.com/azure/architecture/patterns/deployment-stamp). Each deployment stamp is stateless, independent and is considered to be one scale unit. If a stamp is considered to be unhealthy, it can be entirely replaced by a newly deployed healthy stamp.

Azure Mission-Critical stamps share several global resources which are durable through stamp deployments. This document summarizes Business Continuity capabilities and configurations as well as Disaster Recovery processes for each global resource type shared by these deployment stamps.

## Azure Container Registry (ACR)

ACR is used with active-active geo-replication to each region, in which a stamp is deployed. Also, **Zone redundancy** is enabled to provide in-region high availability.

## Cosmos DB

For regular deployments with multiple stamps, Cosmos DB is deployed to **multiple regions with multi-region writes enabled**. Each stamp has a Cosmos DB endpoint in the same region and uses that for writing. As with the rest of the infrastructure, regions with Availability Zones are prioritized and zone redundancy is enabled during region deployment.

**Automatic failover** is enabled so that in case of regional outage Cosmos DB can automatically switch to available regions.

**Backup** is configured with the default settings, i.e. 4 hour periodic backup to geo-redundant storage and 8 hour retention. Continuous backup is not available for the reference implementation because continuous backup cannot be used with Cosmos DB accounts that are configured for multi-region write.

Even though resource management operations are not disabled and the control plane is accessible, data plane operations are restricted by Cosmos DB firewall rules so that there is no direct access to data from the Azure Portal or local machines.

## Azure Front Door

Azure Front Door has WAF (Web Application Firewall) enabled in **Prevention** mode which actively blocks suspicious requests. There are two rulesets configured: `Microsoft_DefaultRuleSet` and `Microsoft_BotManagerRuleSet`.

No additional configuration for BCDR is needed as Front Door is a globally distributed service which manages high availability automatically.

## Azure Monitor

Each stamp in the reference implementation contains its own Log Analytics Workspace and Application Insights instance (There is also a Log Analytics workspace on the global level). Outside of there, there aren't any additional redundancy or highly-available setups implemented.

For cost-saving reasons there are daily data caps configured on stamp and global resources. This can be problematic during load tests as any telemetry beyond these limits is lost.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
