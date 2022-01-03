# Failure analysis

*"What does it take for AlwaysOn to go down?"*

This article walks through a number of possible failure scenarios of the various components of the AlwaysOn reference implementation. It does not claim to be complete since there can always be failure cases which we have not thought of yet. So for any workload, this list should be a living document that gets updated over time.

Composing the failure analysis is mostly a theoretical planning exercise. It can - and should - be complemented by actual failure injection testing. Through testing, at least some of the failure cases and their impact can be simulated and thus validate the theoretical analysis. See [the related article](./DeployAndTest-Testing-FailureInjection.md) for failure injection testing that was done as part of AlwaysOn.

## Outage risks of individual components

Each of the following sections lists risks for individual components and evaluate if their failure can cause an outage of the whole application (the **outage** column).

### Azure Active Directory

| **Risk**              | **Impact/Mitigation/Comment**                | **Outage** |
| ---------------------------------- | ------------------------------------------------------------ | ---------- |
| **Azure AD becomes unavailable** | Currently **no possible mitigation** in place. Also, multi-region approach will likely not (fully) mitigate any outages here as it is a global service. This is a hard dependency we are taking. <br />Mostly AAD is being used for control plane operations like the creation of new AKS nodes, pulling container images from ACR or to access Key Vault on pod startup. Hence, **we expect that existing, running components should be able to keep running when AAD experiences issues**. However, we would likely not be able to spawn new pods or AKS nodes. So in scale operations are required during this time, it could lead to a decreased user experience and potentially to outages. | Partial    |

### Azure DNS

| **Risk**              | **Impact/Mitigation/Comment**                | **Outage** |
| ---------------------------------- | ------------------------------------------------------------ | ---------- |
| **Azure DNS becomes unavailable and DNS resolution fails** | If Azure DNS becomes unavailable, the DNS resolution for user requests as well as between different components of the application will likely fail. Currently **no possible mitigation** in place for this scenario. Also, multi-region approach will likely not (fully) mitigate any outages here as it is a global service. Azure DNS is a hard dependency we are taking. <br />Using some external DNS services as backup would not help much either, since all the PaaS components we are using also rely on Azure DNS.<br /> Bypassing DNS by switching to IP is not an option, because Azure services don’t have static, guaranteed IP addresses. | Full    |

### Front Door

| **Risk**                     | **Impact/Mitigation/Comment**                | **Outage** |
| ------------------------------------------------- | ------------------------------------------------------------ | ---------- |
| **General Front Door outage**          | If Front Door goes down entirely, there is no mitigation for us. We are taking a hard dependency on it. | Yes    |
| **Routing/frontend/backend configuration errors** | **Can happen** due to mismatch in configuration when deploying.<br /> Should be caught in testing stages. However, some things like frontend configuration with DNS is specific to each environment. <br />*Mitigation*: Rolling back to previous configuration should fix most issues. However, as changes take a couple of minutes in Front Door to deploy, it will cause an outage. | Full    |
| **Managed SSL certificate is deleted**      | **Can happen** due to mismatch in configuration when deploying. Should be caught in testing stages. Technically the site would still work, but SSL cert errors will prevent users from using it. <br />If it ever happens, **re-issuing the cert can take around 20 minutes** (plus fixing and re-running the pipeline). | Full    |

### Cosmos DB

Global replication protects Cosmos DB instances from regional outage. The Cosmos SDK maintains an internal list of database endpoints and switches between them automatically.

| **Risk**                   | **Impact/Mitigation/Comment**                | **Outage**                 |
| -------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| **Database/collection is renamed**     | Can happen due to mismatch in configuration when deploying – Terraform would overwrite the whole database, which could result in data loss (this can be prevented by using [database/collection  level locks](https://feedback.azure.com/forums/263030-azure-cosmos-db/suggestions/35535298-enable-locks-at-database-and-collection-level-as-w)). <br />**Application will not be able to access any data**. App configuration needs to be updated and pods restarted. | Yes                     |
| **Regional outage**             | AlwaysOn has multi-region writes enabled, so in case of failure on read or write, the **client retries the current operation** and all the future operations are permanently [routed to the next region](https://docs.microsoft.com/azure/cosmos-db/troubleshoot-sdk-availability#regional-outage) in order of preference. In case the preference list only had one entry (or was empty) but the account has other regions available, it will route to the next region in the account list. | No                     |
| **Extensive throttling due to lack of RUs** | Depending on how we decide on how many RUs (max setting for the auto scaler), we want to deploy and what load balancing we employ on Front Door level, it could be that certain stamp(s) run hot on Cosmos utilization while others could still serve more requests. <br />Could be mitigated by better load distribution to more stamps – or of course more RUs. | No |

### Container Registry

| **Risk**                   | **Impact/Mitigation/Comment**                | **Outage** |
| --------------------------------------------- | ------------------------------------------------------------ | ---------- |
| **Regional outage**              | Container registry uses Traffic Manager to failover between replica regions. Thus, **any request should be automatically re-routed to another region**. At worst, no Docker images can be pulled for a couple of minutes by a certain AKS node while DNS failover needs to happen. | No     |
| **Image(s) get deleted (e.g. by manual error)** | *Impact*: No images can be pulled. This should only affect newly spawned/rebooted nodes. **Existing nodes should have the images cached already.** <br />*Mitigation*: If detected quickly enough, re-running the latest build pipelines should bring the images back into the registry. | No   |

### (stamp) AKS cluster

| **Risk**                          | **Impact/Mitigation/Comment**                | **Outage**       |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------- |
| **Cluster upgrade fails**                  | [AKS Node upgrades](https://docs.microsoft.com/azure/aks/upgrade-cluster) should occur at different times across the stamps. Hence, if one if upgrades fail, other cluster should not be affected. Also, cluster upgrades should happen in a rolling fashion across the nodes so that not all nodes will become unavailable. | No           |
| **Application pod is killed when serving request**      | Should not happen because cluster upgrades use "cordon and drain" with a buffer node. | No           |
| **There is not enough compute capacity in the datacenter to add more nodes** | **Scale up/out operations will fail**, but it shouldn’t affect existing nodes and their operation. Ideally traffic should shift automatically to other regions for load balancing. | No           |
| **Subscription runs out of CPU core quota to add new nodes** | **Scale up/out operations will fail**, but it shouldn’t affect existing nodes and their operation. <br />Ideally traffic should shift automatically to other regions for load balancing. | No           |
| **Let’s Encrypt SSL certificates can’t be issued/renewed** | Cluster should report unhealthy towards Front Door and traffic should shift to other stamps. <br />*Mitigation*: Needs manual investigation on what happened. | No           |
| **Pod utilization reaches the allocated capacity**      | When resource requests/limits are configured incorrectly, pods can reach 100% CPU utilization and start failing requests. <br />During load test **the observed behavior wasn’t blocking** – application retry mechanism was able to recover failed requests, causing a longer request duration, without surfacing the error to the client. Excessive load would eventually break it. | No (if not excessive) |
| **3rd-party container images / registry not available** | Some components like cert-manager and ingress-nginx require downloading container images from external container registries (outbound traffic). In case one or more of these repositories or images are unavailable, new instances on new nodes (where the image is not already cached) might not be able to start. | Partially (during scale and update/upgrade operations) |

### (stamp) Event Hub

| **Risk**                    | **Impact/Mitigation/Comment**                | **Outage** |
| ---------------------------------------------- | ------------------------------------------------------------ | ---------- |
| **No messages can be sent to the Event Hub** | Stamp becomes unusable for any write operations. **Health service should automatically detect this** and take the stamp out of rotation | No     |
| **No messages can be read by the BackgroundProcessor** | Messages will queue up, but no messages should get lost since they are persisted. <br />**Currently this is not covered by the Health Service**. But there should be monitoring/alerting in place on the Worker to detect errors in reading messages.<br/>*Mitigation*: The stamp needs to be manually disabled until the problem is fixed. | No     |

### (stamp) Storage Account

| **Risk**                           | **Impact/Mitigation/Comment**                | **Outage** |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---------- |
| **Storage account becomes unusable by the Worker for Event Hub checkpointing** | **Stamp will not be able to process any messages from the Event Hub.** <br />The storage account is also used by the HealthService, so we expect issues with storage to be detected by the HealthService and the stamp should be taken out of rotation. <br />Anyway, as Storage is a foundational service, it can be expected that other services in the stamp would also be impacted at the same time. | No     |
| **Static website encounter issues**             | If serving of the static web site encounters any issues, this should be detected by Front Door and no more traffic should be send to this storage account. Plus, we will use caching in Front Door as well. | No     |

### (stamp) Key Vault

| **Risk**                           | **Impact/Mitigation/Comment**                | **Outage** |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---------- |
| **Key Vault becomes unavailable for GetSecret operations** | At the start of new pods, the AKS CSI driver will fetch all secrets from Key Vault. This would not work; **hence we cannot start new pods anymore**.<br />There is also automatic update (currently every 5 minutes). The update will fail (errors show up in `kubectl describe pod` but the pod keeps working. | No     |
| **Key Vault becomes unavailable for GetSecret or SetSecret operations** | No new deployments can be executed. Currently, **this might cause the entire deployment pipeline to stop**, even if only one region is impacted. | No     |
| **Key Vault throttling kicks in**              | Key Vault has a limit of 1000 operations per 10 seconds. Due to the automatic update of secrets, we could in theory hit this limit if we had many (thousands) of pods in a stamp. <br />*Possible mitigation*: Decrease update frequency even further or turn it off completely. | No     |

### (stamp) Application

| **Risk**        | **Impact/Mitigation/Comment**                | **Outage** |
| ----------------------- | ------------------------------------------------------------ | ---------- |
| **Misconfiguration**  | Incorrect connection strings or secrets injected to the app. Should be mitigated by automated deployment (pipeline handles configuration automatically) and blue-green rollout of updates. | No     |
| **Expired credentials (stamp resource)**  | If, for example, Event Hub SAS token or Storage Account key was changed without properly updating them in Key Vault so that the pods can use them, the respective application component will start to fail. This should then also affect the Health Service and hence **the stamp should be taken out of rotation automatically**.<br/>*Mitigation*: As a potential way to not run into these issues in the first place, using AAD-based authentication all services which support it, could be implemented. However, when using AKS, this would require to use Pod Identity to  use Managed Identities within the pods. We considered this but found pod identity not stable enough yet and thus decided against using it for now. But this could be a solution in the future.  | No     |
| **Expired credentials (globally shared resource)**  | If, for example, Cosmos DB API key was changed without properly updating it in all stamp Key Vaults so that the pods can use them, the respective application components will start to fail. **This would likely bring all stamps down at about the same time and cause an workload-wide outage.** See the article on [Key Rotation](./OpProcedures-KeyRotation.md) for an example walkthrough how to execute this process properly without downtime. For a possible way around the need for keys and secrets in the first place using AAD auth, see the previous item. | Full     |

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
