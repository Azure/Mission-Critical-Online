# General infrastructure design decisions

## Naming conventions

All resources used for AlwaysOn follow a pre-defined and consistent naming structure to make it easier to identify them and to avoid confusion. Resource abbreviations are based on the [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations#general). These abbreviations are typically attached as a suffix to each resource in Azure.

A **prefix** is used to uniquely identify "deployments" as some names in Azure must be worldwide unique. Examples of these include Storage Accounts, Container Registries and CosmosDB accounts.

**Resource groups**

Resource group names begin with the prefix and then indicate whether they contain per-stamp or global resources. In case of per-stamp resource groups, the name also contains the Azure region they are deployed to.

`<prefix><suffix>-<global | stamp>-<region>-rg`

This will, for example, result in `aoprod-global-rg` for global services in prod or `aoprod7745-stamp-eastus2-rg` for a stamp deployment in `eastus2`.

**Resources**

`<prefix><suffix>-<region>-<resource>` for resources that support `-` in their names and `<prefix><region><resource>` for resources such as Storage Accounts, Container Registries and others that do not support `-` in their names.

This will result in, for example, `aoprod7745-eastus2-aks` for an AKS cluster in `eastus2`.

## Subscriptions

AlwaysOn uses a strict separation between production and non-production environments through the use of individual Azure Subscriptions. Developers might still require write access to dev and test environments for development, testing and troubleshooting, however, for production environments, write access is limited to Service Principals only. See [Subscription decision guide](https://docs.microsoft.com/azure/cloud-adoption-framework/decision-guides/subscriptions/) in the [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/) for more.

All components of a given environment are currently deployed into a single Azure subscription. At this time, AlwaysOn does not include the option to deploy global services and stamps across more than one Azure subscription. This design decision introduces some limits for requests, throttling and quotas.

| Resource | Limits | Impact on AlwaysOn | Severity |
| --- | --- | --- | --- |
| [Max. clusters per subscription](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-kubernetes-service-limits) | 5000 | Max. 5000 stamps | Low |
| [Max. nodes per cluster](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-kubernetes-service-limits) | 1000 (across all node pools) | Stamps will not scale to 1000 nodes | Low |
| [Resource groups per subscription](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#subscription-limits) | 980 | One RG per stamp + global and shared services | Low |

> This list of limits is not complete and subject to change. See [Azure subscription limits](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits) for more details.

> **Important!** It is also important to monitor the [Azure subscription request limits and throttling](https://docs.microsoft.com/azure/azure-resource-manager/management/request-limits-and-throttling) as well as per-subscription quotas (such as CPU cores) to ensure enough capacity is available for scale operations.

## Stamp independence

Every [stamp](https://docs.microsoft.com/azure/architecture/patterns/deployment-stamp) - which usually corresponds to a deployment to one Azure Region - is considered independent. Stamps are designed to work without relying on components in other regions (i.e. "share nothing").

The main shared component between stamps which requires synchronization at runtime is the database layer. For this, **Azure Cosmos DB** was chosen as it provides the crucial ability of multi-region writes i.e., each stamp can write locally with Cosmos DB handling data replication and synchronization between the stamps.

Aside from the database, a geo-replicated **Azure Container Registry** (ACR) is shared between the stamps. The ACR is replicated to every region which hosts a stamp to ensure fast and resilient access to the images at runtime.

Stamps can be added and removed dynamically as needed to provide more resiliency, scale and proximity to users.

A global load balancer is used to distribute and load balance incoming traffic to the stamps (see [Networking](./Networking-Design-Decisions.md) for details).

## Stateless compute clusters

As much as possible, no state should be stored on the compute clusters with all states externalized to the database. This allows users to start a user journey in one stamp and continue it in another.

## Scale Units (SU)

In addition to [stamp independence](#stamp-independence) and [stateless compute clusters](#stateless-compute-clusters), each "stamp" is considered to be a Scale Unit (SU) following the [Deployment stamps pattern](https://docs.microsoft.com/azure/architecture/patterns/deployment-stamp). All components and services within a given stamp are configured and tested to serve requests in a given range. This includes auto-scaling capabilities for each service as well as proper minimum and maximum values and regular evaluation.

An example SU design in AlwaysOn consists of scalability requirements i.e. minimum values / the expected capacity:

**Scalability requirements**
| Metric | max |
| --- | --- |
| Users | 25k |
| New games/sec. | 200 |
| Get games/sec. | 5000 |

This definition is used to evaluate the capabilities of a SU on a regular basis, which later then needs to be translated into a Capacity Model. This in turn will inform the configuration of a SU which is able to serve the expected demand:

**Configuration**
| Component | min | max |
| --- | --- | --- |
| AKS nodes | 3 | 12 |
| Ingress controller replicas | 3 | 24 |
| Game Service replicas | 3 | 24 |
| Result Worker replicas | 3 | 12 |
| Event Hub throughput units | 1 | 10 |
| Cosmos DB RUs | 4000 | 40000 |

> Note: Cosmos DB RUs are scaled in all regions simultaneously.

Each SU is deployed into an Azure region and is therefore primarily handling traffic from that given area (although it can take over traffic from other regions when needed). This geographic spread will likely result in load patterns and business hours that might vary from region to region and as such, every SU is designed to scale-in/-down when idle.

## Availability Zones

- Only Azure regions which offer **[Availability Zones](https://docs.microsoft.com/azure/availability-zones/az-region)** are considered for a stamp to provide in-region redundancy.
- Wherever possible zone-redundant SKUs of a service are used. Currently (September 2021) the following used services do not offer explicit zone redundancy in GA:
  - Log Analytics workspaces (and thus Application Insights)
  - Azure Container Registry: Zone-redundancy is still in public preview in only a limited number of regions, however, the Terraform templates are already prepared to switch the feature on once it is GA.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
