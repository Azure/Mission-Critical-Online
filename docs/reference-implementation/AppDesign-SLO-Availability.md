# SLO and Availability

AlwaysOn has set a targeted availability of **99.95%**. This document covers the reasoning and how this number was defined.

> While it is understood that the implementation is literally called "AlwaysOn" and therfore implies availability of 100%, in cloud reality this number is extremely difficult to achieve. Instead it is accepted that each component can/ will become unavailable at some point and have designed the architecture to be as tolerant and adaptive to this as possible.

## Service Level Agreement (SLA) and Service Level Objective (SLO)

An **SLA** describes a contractual commitment for application availability and as the purpose of AlwaysOn is not to define contractual agreements, we prefer an availability target in the form of **SLO**. This is a percentage figure which represents the amount of time in a month when the application is *available*.

**Availability** for AlwaysOn means that end users are able to perform game operations using the website. These operations include:

1. Enter the home page.
1. Sign in with provided credentials.
1. Access their profile.
1. Play a game against AI.
1. See the leaderboard.

An SLO of 99.95% equates to an accepted downtime of **5 minutes per week** or **21.6 minutes per month** (This does not mean that an outage will necessarily happen, but if it did, this is the target outage duration which should be expected).

## Composite SLA

To define a realistic SLO it is important to understand the SLAs of the individual Azure components. Cloud services rely on each other and can potentially fail at the same time, therefore, their availability numbers need to be combined into a Composite SLA.

> While AlwaysOn does not have contract with its users (hence providing an SLO not SLA) it does have one with Azure and so we can consider the official SLAs of the platform.

Composite SLA is calculated as individual SLAs multiplied with each other.

Example:

- *SLAcomposite = (SLAdns × SLAcosmos × SLAfrontdoor × SLAactivedirectory)*

- *SLAcomposite = 1 × 0.99999 × 0.9999 × 0.9999 = 0.99979 = 99.979%*

***Global tier***

| Azure Service                          | SLA      |
| -------------------------------------- | -------- |
| Azure DNS                              | 100.000% |
| Cosmos DB (Multiple Writable Replicas) | 99.999%  |
| Front Door                             | 99.990%  |
| Azure Active Directory                 | 99.990%  |

Composite SLA of global tier: **99.979%**.

***Stamp tier***

| Azure Service                   | SLA     |
| ------------------------------- | ------- |
| VMs (AZ)                        | 99.990% |
| AKS Control Plane w/ Uptime SLA | 99.950% |
| Event Hubs                      | 99.950% |
| Storage - ZRS (Hot Blobs)       | 99.900% |
| Standard Load Balancer          | 99.990% |
| Key Vault                       | 99.990% |

Composite SLA of Stamp tier: **99.77%**.

## Final SLO

The fact that AlwaysOn uses multiple stamps improves the Stamp tier availability and resiliency, but at the same time the hard dependency on the Global tier limits the overall achievable availability. This also means that adding more stamps will not improve the overall infrastructure SLA, however, this can improve performance and resiliency in case a stamp fails.

The maximum availability (based on the underlying Azure infrastructure) is 99.979% when running with at least **three** stamps. To allow for deployments and application-level outages, this number was reduced slightly to **99.95%**.

- Maximum infrastructure SLA = 99.979% = 9.52 minutes of allowed downtime per month
- AlwaysOn SLO = 99.95% = 21.6 minutes of allowed downtime per month

https://docs.microsoft.com/azure/architecture/framework/resiliency/business-metrics

## Observability

AlwaysOn uses Application Insights availability probes to probe health endpoints for each stamp every 5 minutes. If the probe responds with success, then the website storage account is reachable. These are the same probing calls which Azure Front Door uses to determine backend health.

![Availability in Application Insights](/docs/media/SLA-appi-availability.png)

Application Insights also generates a comprehensive SLA report where outages can be monitored and downtime measured.

![Downtime and outage report](/docs/media/SLA-downtime-outage.png)

Availability can also be observed via Front Door backend monitoring which is based on the health probes and shows the health of each of the configured backends.

![Front Door backend health](/docs/media/SLA-backend-health-fd.png)

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
