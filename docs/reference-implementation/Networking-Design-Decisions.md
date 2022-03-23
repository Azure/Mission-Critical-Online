# Networking design decisions

## Virtual network layout

- Each stamp uses its own Virtual Network (VNet) and as there is no cross-stamp traffic, no VNet peerings or VPN connections to other stamps are required.
- The per-stamp VNet is currently only having one subnet for Kubernetes (containing all nodes and pods).

## Global load balancer

**Azure Front Door** (AFD) is used as the global entry point for all incoming client traffic. As Azure Mission-Critical only uses HTTP(S) traffic and uses Web Application Firewall (WAF) capabilities, AFD is the best choice to act as global load balancer. Azure Traffic Manager could be a cost-effective alternative, but it does not have features such as WAF and because it is DNS-based, Azure Traffic Manager usually has longer failover times compared to the TCP Anycast-based Azure Front Door.

See [Custom Domain Support](./Networking-Custom-Domains.md) for more details about the implementation and usage of custom domain names in Azure Mission-Critical.

## Stamp ingress point

- As Azure Front Door does not (currently) support private origins (backends), the stamp ingress point must be public (private origins are currently planned for Public Preview in the next version of Front Door).
- The entry point to each stamp is a public **Azure Standard Load Balancer** (with one zone-redundant public IP) which is controlled by **Azure Kubernetes Service** (AKS) and the Kubernetes Ingress Controller (Nginx).
- **Azure Application Gateway** is not used because it does not provide sufficient added benefits (compared to AFD):
  - Web Application Firewall (WAF) is provided as part of Azure Front Door.
  - TLS termination happens on the ingress controller and thus inside the cluster.
  - Using cert-manager, the procurement and renewal of SSL certificates is free of charge (with Let's Encrypt) and does not require additional processes or components.
  - Azure Mission-Critical does not have a requirement for the AKS cluster to only run on a private VNet and therefore, having a public Load Balancer in front is acceptable.
  - (Auto-)Scaling of the ingress controller pods inside AKS is usually faster than scaling out Application Gateway to more instances.
  - Configuration settings including path-based routing and HTTP header checks could potentially be easier to set up using Application Gateway. However, Nginx provides all the required features and is configured through Helm charts.

## Network security

- Traffic to the cluster entry points must only come through the global load balancer (Azure Front Door). To ensure this, HTTP header inspection [based on the `X-Azure-FDID` header](https://docs.microsoft.com/azure/frontdoor/front-door-faq#how-do-i-lock-down-the-access-to-my-backend-to-only-azure-front-door-) is implemented on the Nginx ingress controller.
- There is no additional firewall in place (such as Azure Firewall) as it provides no added benefits for reliability but instead would introduce another component adding further management overhead and failure risk.
- Network Service Endpoints are used to lock down traffic to all services which support them.
- In accordance with [Azure Networking Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices), all subnets have Network Security Groups (NSGs) assigned.
- TLS termination happens at the ingress controllers. To issue and renew SSL certificates for the cluster ingress controller, the free Let's Encrypt Certificate Authority is used in conjunction with [cert-manager](https://cert-manager.io/docs/) Kubernetes certificate manager.
- As there is no direct traffic between pods, there is no requirement for mutual TLS to be configured.

## Considerations on not using fully private clusters as the default deployment mode

The main motivation of Azure Mission-Critical is to build a highly reliable solution on Azure.

The default version of the Reference Implementation of Azure Mission-Critical does not use [fully private compute clusters](https://docs.microsoft.com/azure/aks/private-clusters) and does not fully lock down traffic for all Azure PaaS services.

These decisions are explained further below:

> It is acknowledged that these decisions might not suit every use case, for instance in some regulated industries. Therefore, there is an alternative version of the Reference Implementation  which deploys in a [Private Mode](https://github.com/Azure/Mission-Critical-Connected). However, this comes potentially at the expense of higher cost and reliability risk. Thus, the requirements and impact should be fully understood before making the switch.

### Public compute cluster endpoint

> The first version of the reference implementation exposes the AKS cluster with a public load balancer that is directly accessible over the internet.

- The current version of Azure Front Door only supports backends (origins) with public endpoints; the same would have been true with Traffic Manager if used as an alternative global load balancer. In order to not have a public endpoint on the compute cluster some additional service would have been required in the middle, such as Azure Application Gateway or Azure API Management. However, these would not add functionality, only complexity - and more potential points of failure.
- A risk of publicly accessible cluster ingress points is that attackers could attempt [DDoS](https://en.wikipedia.org/wiki/Denial-of-service_attack) attacks against the endpoints. However, [Azure DDoS protection Basic](https://docs.microsoft.com/azure/ddos-protection/ddos-protection-overview) is in place to lower this risk. If required, DDoS Protection Standard could optionally be enabled to get even more tailored protection.
- If attackers successfully acquire the Front Door ID which is used as the filter on the ingress level, they could directly reach the workload's APIs. However, the attacker would only succeed in circumventing the Web Application Firewall of Front Door. This was judged a small enough risk that the benefit of higher reliability through reduced complexity outweighed the minimal added protection of additional components.

### Use of Private Endpoints for PaaS

- The Online Reference Implementation does not use Private Endpoints to limit access to the used PaaS services. This is to simplify the onboarding and facilitate an easier learning curve for users. For production workloads, the use of Private Endpoints is highly recommended, like it is shown also in the [Mission-Critical Connected Reference Implementation](https://github.com/Azure/Mission-Critical-Connected).

### Requirements to utilize a fully private cluster

As described above, to remove the public endpoint on the compute clusters, another component such as Application Gateway would be required. In the future, the new [Azure Front Door Standard/Premium](https://docs.microsoft.com/azure/frontdoor/standard-premium/overview) offering will eliminate the need for this, as it will support private origins as well (in Public Preview as of October 2021).

A more significant change if using private endpoints is the switch from hosted Build Agents (managed by Microsoft) to [self-hosted agents](https://docs.microsoft.com/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser#install) which will need to be VNet-integrated in order to reach private services like Key Vault or AKS. Managing these agents and keeping them updated adds additional overhead and is not recommended as long as there is no actual requirement to switch to a fully private deployment.

To deploy Reference Implementation in a private configuration, follow the guides of [this GitHub repository](https://github.com/Azure/Mission-Critical-Connected).

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
