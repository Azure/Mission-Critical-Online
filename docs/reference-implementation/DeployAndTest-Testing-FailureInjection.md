# Failure Injection Testing

Based on the [Failure Analysis](./Health-Failure-Analysis.md), the Azure Mission-Critical team performed some manual failure injection testing (also known as "Chaos Testing" or "Chaos Monkey testing"). This article shares some learnings around what was tested and how this informed the development of the solution.

When the Azure Mission-Critical project started, no automated Failure Injection Testing was implemented and a series of manual testing was performed which provided a lot of valuable insights.

All tests were performed in an E2E validation environment so that fully representative tests could be conducted without any risk of interference from other environments. Most of the failures can be observed directly in the Application Insights [Live metrics](https://docs.microsoft.com/azure/azure-monitor/app/live-stream) view - and a few minutes later in the Failures view and corresponding log tables. Other failures need deeper debugging such as the use of `kubectl` to observe the behavior inside of AKS.

## DNS-based failure injection

DNS failure injection is a good test case since it can simulate multiple issues. Firstly it simulates the case when the DNS resolution fails, for instance because Azure DNS experiences an issue ,but it can also help to simulate general connection issues between a client and a service, for example when the BackgroundProcessor cannot connect to the Event Hub.

In single-host scenarios you can simply modify the local `hosts` file to overwrite DNS resolution. In a larger system with multiple dynamic servers like AKS, this is not feasible. However, we can use [Azure Private DNS Zones](https://docs.microsoft.com/azure/dns/private-dns-privatednszone) as an alternative (See the Event Hubs example below for a configuration walk-through).

### Event Hub

1) [Create a Private DNS Zone](https://docs.microsoft.com/azure/dns/private-dns-getstarted-cli#create-a-private-dns-zone) with the name of the service you want to fail e.g. `servicebus.windows.net`.
1) [Link](https://docs.microsoft.com/azure/dns/private-dns-virtual-network-links) this Private DNS Zone to the VNet of one of the stamps where you want to perform the test.
1) Without creating any further records, name resolution to any Event Hub (or Service Bus) namespace will start to fail as the Zone does not contain a record for, e.g. `ao1234-northeurope-evhns.servicebus.windows.net`.
1) For a slightly different test case, you can also create an "A" record in that zone for `ao1234-northeurope-evhns` to resolve to an arbitrary IP address. This way the DNS resolution itself will still work but the expected connection at the IP address won't.
1) Note that DNS resolutions might have been cached at different layers, for example in an AKS node, so it might take a few minutes until the first errors occur. Note existing client connections often continue to work for a longer period, however, new connections, should start to fail, for instance when a new pod is started.

### Cosmos DB

As Cosmos DB is a globally replicated service with specific regional endpoints, manipulating the DNS records for those endpoints is a very valuable exercise as it can simulate the failure of one specific region and test the failover of the clients. To simulate e.g. an outage of the North Europe regional endpoint, we can create a faulty DNS record as described above for the endpoint `ao1234-global-cosmos-northeurope.documents.azure.com`. Again, based on existing connections and their DNS refresh it might take a few minutes until connections to this endpoint start to fail. Then, the Cosmos DB SDK will transparently retry and then failover to the next endpoint in the list of available endpoints which it first gathered on the [Cosmos DB metadata endpoint](https://docs.microsoft.com/azure/cosmos-db/tutorial-global-distribution-sql-api?tabs=dotnetv2%2Capi-async#rest).

As this retry and failover logic in the SDK takes about 2 minutes, the Health Service in its previous configuration would time out before that and thus mark the entire stamp unhealthy. Therefore, as a learning point from the testing, the timeout setting on the Health Service was increased to cater for this.

## Firewall blocking

Most Azure services support firewall access restrictions based on VNets and/or IP addresses. In Azure Mission-Critical these are already used to restrict access, for instance, to Cosmos DB or Event Hub. Blocking access by removing existing Allow rules or adding new Block rules is a straightforward test. This can serve to simulate firewall misconfigurations but also actual service outages. Note that similar to above, existing established connections might continue to work for a period before they start to fail.

### Key Vault

When access to Key Vault was blocked on a firewall level, the most direct impact it has is that no new pods can be spawned. The Key Vault CSI driver used to fetch secrets on pod startup cannot perform its tasks and thus prevents the pod from starting. Corresponding error messages can be observed using `kubectl describe po CatalogService-deploy-my-new-pod -n workload`.

Existing pods will continue to work, although the same error message as above can be observed - this is caused by results from the periodic update check on secrets.

Although untested, it is assumed that that running a deployment would not work while Key Vault is not accessible as both Terraform and various Azure CLI tasks make requests to Key Vault during the pipeline run.

### Event Hub

When access to Event Hub was blocked the sending of new messages by the CatalogService and HealthService and retrieving of messages by the BackgroundProcessor slowly started to fail taking a few minutes for total failure. This is likely because long-standing AMQP connections are not immediately closed when new firewall restrictions are created.

### Cosmos DB

Blocking access to Cosmos DB by removing the existing firewall access policy for a particular VNet causes the Health Service to start failing with very little lag. Unfortunately this only simulates a very specific case i.e. an entire Cosmos DB outage. Most failure cases which occur on a regional level should be mitigated automatically by transparent failover of the client to a different Cosmos DB region. Therefore, the DNS-based failure injection testing as described above is more meaningful for Cosmos DB.

### Container Registry (ACR)

Once access to ACR is blocked, any creation of new pods which have been pulled and cached previously on an AKS node still works. This is due to the k8s deployment flag `pullPolicy=IfNotPresent`. However, nodes which have not pulled and cached a specific image beforehand cannot spawn the pod and fail immediately with `ErrImagePull` errors. `kubectl describe pod` shows the corresponding `403 Forbidden` message.

### AKS Ingress Load Balancer

> The following failure injection test was carried out as part of a working session in which one team member introduced a fault while the others tried to detect it, find the root cause and attempt to fix it. Exercises like this can be hugely beneficial to train operation teams how to react to issues.

By changing the inbound rules for HTTP(S) (ports 80 and 443) on the AKS-managed Network Security Group (NSG), which lives in the managed resource group of AKS, to **Deny**, user or health probe traffic could no longer reach the cluster. Testing this failure, it is difficult to pinpoint the actual root cause - which was simulated to be some blockage in the network path between Front Door and the regional stamp.

Front Door immediately detected this failure and the stamp was taken out of rotation, however, there was no logging provided by Front Door to allow us to determine the reason why a backend was marked as "unhealthy" (a non-200 response or unable to reach the HealthService in the first place). So starting the investigation - quite naturally - on the HealthService didn't reveal any issues until we realized that it was not getting any more requests from Front Door.

From there on there were still several components in place which could have been the cause of the issue: Ngnix Ingress Controller (pods not working or misconfigured?) and its k8s Service definition, the public Load Balancer as well as the Public IP. In this case, only a manual test to reach the URL of the cluster's public HTTP endpoint revealed a failed connection. This, however, only narrowed down the failure analysis slightly.

Overall, this particular failure injection showed that even for a skilled operations team it can be quite challenging to detect (and then attempt to fix) the root cause of an issue in a distributed system.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
