# Operational Procedures

As discussed in other sections of this AlwaysOn Top Level Guidance, one of the key principles of AlwaysOn is to use automation wherever possible. Furthermore, all configuration is to be defined as code and versioned in the repository and executed via pipeline(s). While this takes effort to set up and discipline to maintain, it does lead to a state where day-to-day operational tasks in an AlwaysOn solution are usually minimal.

## Design Recommendations

- Wherever possible, configuration settings and updates on the infrastructure and application are to be defined in code. As such, any changes to that code is managed through the regular release and update process. This also involves tasks such as key or secret rotations and permission management.
- Identify critical alerts and define target audiences/systems and channels to reach them, in line with the health model. It is important to send only actionable alerts otherwise people will likely start to ignore them and miss important information.
- Use Managed Identities in order to avoid dealing with Service Principal credentials or API keys.
- Use built-in capabilities for SSL certificate management and renewal (for example in Azure Front Door).
- Use platform-native capabilities for backup/restore instead of building custom solutions.
  - Familiarize yourself with the available backup retention options. Define a strategy for long-term backup retention, if required.
- Use an active-active setup where possible so that no intervention is needed for failover.
- If active-passive (or active-read replica) is the only option, make sure failover procedures are automated or at least codified in pipelines so that no manual steps need to be executed in times of emergency.
- Update external libraries, SDK and runtime version frequently and treat it as any other change to the application.

## Design Considerations

- For operational tasks, such as secret rotation and other ops tasks, these are to be handled in a regular release with code/config changes.
- Where manual changes are required (this should only ever happen in cases of emergency), ensure that there is a process in place to reconciliate those manual changes back into the repository.
- Where you cannot use Managed Identities or managed SSL certificates, have processes in place to monitor/alert key/secret and certificate expiries as these are a major cause of outages. In line with this recommendation, updating those should be carried out via the regular release process.
- Define emergency processes for Just-in-time access for the production environment as well as break glass accounts in case there are issues with the authentication provider.
- Validate and update 3rd party libraries and SDK on a regular base to ensure that security vulnerabilities and performance optimizations are applied.

## Service-Level Considerations

Individual Azure services have different operational capabilities, especially when it comes to procedures around backup, recovery and high availability.

This section covers most common services used in AlwaysOn and their approach to disaster recovery and operational procedures.

### Azure Container Registry (ACR)

#### High Availability

ACR supports High Availability as follows:

1. [Geo-replication](https://docs.microsoft.com/azure/container-registry/container-registry-geo-replication#considerations-for-high-availability) to multiple configured regions to provide resiliency against a region becoming unavailable. (This also provides network-close registry access in each configured region, reducing network latency and cross-region data transfer costs.)
2. If a geo-replication region becomes unavailable, the other regions will continue to serve image requests. When the region becomes available, ACR will recover the region and replicate any changes to it.
3. In Azure regions with Availability Zones, the [Premium ACR tier supports Zone Redundancy](https://docs.microsoft.com/azure/container-registry/zone-redundancy) to protect against zonal failure. (Zone redundancy for ACR is in public preview as of September 2021 and not available in all regions.)

Configuring ACR for Geo-Replication across more than one Azure region and preferring Azure regions with AZ support is the optimal strategy for high availability in ACR.

#### Container Image Locking

By default, [tagged ACR images are mutable](https://docs.microsoft.com/azure/container-registry/container-registry-image-lock#scenarios), meaning that the same tag can be used on multiple images successively pushed to the registry. In production scenarios, this may lead to unpredictable behaviors affecting application uptime.

ACR supports [locking an image version or a repository](https://docs.microsoft.com/azure/container-registry/container-registry-image-lock) to prevent changes or deletes. This protects against an image being unavailable, which would decrease the Container Registry's availability to consuming application platforms. Image Locking also protects against a specific, previously-deployed image *version* being changed in-place, which would introduce the risk that same-version deployments before and after such a change may have different behaviors.

Locking Container Images does not protect against the Registry itself being deleted. See "[Lock resources to prevent unexpected changes](https://docs.microsoft.com/azure/azure-resource-manager/management/lock-resources)" for additional Registry protection.

### Azure Cosmos DB

#### High Availability

Cosmos DB supports High Availability as follows:

1. Cosmos DB maintains four replicas of data within a region. In regions with Availability Zone (AZ) support, Cosmos DB ensures replicas are placed across multiple AZs to protect against zonal failures.
2. Cosmos DB replicates data across regions configured within a Cosmos DB account. Using multiple regions protects against a single region becoming unavailable.
3. Cosmos DB can be configured for single-region write or multi-region write. With single-region write, if the write region becomes unavailable, a failover operation (automatic or manual) must occur to make another region writable. With multi-region write, applications can write to any region and data is internally replicated between regions.
4. [Cosmos DB can be configured for autoscale](https://docs.microsoft.com/azure/cosmos-db/provision-throughput-autoscale) to enable Cosmos DB resources to scale up and down in response to variable workload levels. Static provisioned throughput with a variable workload may result in throttling errors, which will be perceived as reduced availability by clients. Autoscale protects against throttling errors by enabling Cosmos DB to scale up as needed, while maintaining cost protection by scaling back down when load decreases.

Using more than one region, prioritizing regions with AZ support, configuring autoscale provisioned throughput, and using multi-region write is the optimal strategy for high availability in a Cosmos DB account.

#### Data Protection with Backup and Recovery

Cosmos DB has two backup modes: Periodic and Continuous. The following summarizes procedures to back up data, and to restore data in case of data loss.

Consult the Cosmos DB Documentation for details:

- [Backup and restore introduction](https://docs.microsoft.com/azure/cosmos-db/online-backup-and-restore)
- [Periodic Backup](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore)
- [Continuous Backup](https://docs.microsoft.com/azure/cosmos-db/continuous-backup-restore-introduction)

##### General Information

The following applies to both backup modes:

- Automatic backups do not affect Cosmos DB availability or performance
- Backups do not consume RUs
- Backups are stored in Azure Storage and cannot be directly accessed by customers
- Existing accounts can be migrated from Periodic to Continuous, but not from Continuous to Periodic Backup
  - Migration is one-way and not reversible
- Azure Synapse Link analytical store data is not included in Cosmos DB backups or restores
- The following source capabilities or settings are restored:
  - The data itself
  - Provisioned throughput
  - Indexing policies
  - Azure region(s)
  - Container TTL settings
- The following source capabilities or settings are **not restored**:
  - Firewall settings: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts?tabs=json#ipaddressorrange-object), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb?view=azure-cli-latest#az_cosmosdb_create) --> `ip-range-filter`
  - VNet access control lists: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb/network-rule)
  - Private endpoint settings: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts/privateendpointconnections), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb/private-endpoint-connection)
  - Consistency settings: by default the account is restored with session consistency: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts?tabs=json#consistencypolicy-object), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb?view=azure-cli-latest#az_cosmosdb_update) --> `default-consistency-level`
  - Stored procedures: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts/sqldatabases/containers/storedprocedures), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb/sql/stored-procedure)
  - Triggers: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts/sqldatabases/containers/triggers), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb/sql/trigger)
  - UDFs: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts/sqldatabases/containers/userdefinedfunctions), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb/sql/user-defined-function)
  - Multi-region settings: [ARM template](https://docs.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts?tabs=json#Location), [Azure CLI](https://docs.microsoft.com/cli/azure/cosmosdb)
- Customers are responsible for re-deploying capabilities and settings that are not restored by Cosmos DB Restore
  - Applicable after restore of account, database, or container
  - Example: deploy ARM template(s) or run Azure CLI script(s) to re-establish these settings

##### Periodic Backup

- Default backup mode for all existing Cosmos DB accounts
  - Newly created accounts without specified Backup mode will default to Periodic Backup
- By default, Geo-Redundant (GRS) Azure Storage is used for resiliency. Customers can [change this to Zone-Redundant (in supported Azure regions) or Locally-Redundant](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore#backup-storage-redundancy) if needed
- Default backup interval is every four hours
  - Minimum is every one hour, maximum is every 24 hours
- Default backup retention is eight hours
  - With default backup interval of four hours, this means last two backups retained
  - Minimum is two hours, maximum is 720 hours
  - Two backup copies are included at no extra cost; customers can configure additional backup copy retention at extra cost
- **Restore requires a Support Request** - customers cannot perform a Restore themselves
  - Before [opening a Restore support ticket](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore#request-restore), customers should [increase backup retention to at least seven days, within eight hours of the data loss event](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore#configure-backup-interval-retention)
- Restore always creates a new Cosmos DB account to which data is restored - an existing Cosmos DB account cannot be used for Restore
  - By default, Restore will create a new Cosmos DB account named `<Azure_Cosmos_account_original_name>-restored<n>` - this can be adjusted if needed (e.g. if the original account was deleted, its name can be reused)
- If throughput was provisioned at the database level, backup and restore happen at the database level; customers cannot select a subset of containers to restore
- Users must have a role assignment to the Azure "Cosmos DB Account Reader Role" in order to be able to configure backup storage redundancy
- Subscription admin or co-admins can see restored Cosmos DB accounts

##### Continuous Backup

- **A Cosmos DB account cannot have both multi-region write and Continuous Backup** - customers must choose one of these mutually exclusive options
- Only SQL API and API for MongoDB accounts can be configured for Continuous backup
- An existing Cosmos DB account can only be _migrated_ from Periodic to Continuous if all the following are true:
  - Account is SQL API or API for MongoDB
  - Account has a single write region
  - Account does not use Customer-Managed Keys (CMK)
  - Account is not enabled for Analytical Store
- Continuous backups are taken in every Azure region where the Cosmos DB account exists
- Backups are stored in Azure storage in the same Azure region as each Cosmos DB replica
- By default, Locally-Redundant (LRS) Azure Storage is used for resiliency, but this can be adjusted
  - If an Azure region supports AZs, then Zone-Redundant Storage (ZRS) is used by default
- In steady state, all mutations on the source account (which includes databases, containers, and items) are backed up asynchronously within 100 seconds
- Restores are to a specific point in time (PITR) with a one-second granularity
- The available time window for restore (aka retention period) is the lower of 30 days, or back to the resource creation time
- Customers can perform self-service Restore using any of the following:
  - [Azure portal](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-portal)
  - [Azure CLI](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-cli)
  - [Azure PowerShell](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-powershell)
  - [ARM template](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-arm-template)
- Restore always creates a new Cosmos DB account to which data is restored - an existing Cosmos DB account cannot be used for Restore
- There is [additional cost for storage of Continuous Backup data, and for restore operations](https://docs.microsoft.com/azure/cosmos-db/continuous-backup-restore-introduction#continuous-backup-pricing)
- If a container had TTL configured, restored data that has exceeded its TTL may be _immediately deleted_
- There are [additional limitations](https://docs.microsoft.com/azure/cosmos-db/continuous-backup-restore-introduction#current-limitations) on Continuous Backup

##### Custom Backup and Restore

Customers for whom neither Periodic nor Continuous backup/restore are a good fit can build a custom backup and restore capability. This should be carefully considered, tested, and the additional cost and administrative overhead justified.

This approach may be justified if a customer requires both multi-region write _AND_ self-service restore (which only Continuous backup provides at this time) or has another scenario unsupported in either Periodic or Continuous backup/restore.

###### Considerations

A custom backup/restore implementation will need to address the following considerations:

- Selection of backup storage. This can be another Cosmos DB container (in the same or another account and database), Azure Storage, or another suitable repository. Either Cosmos DB or Azure Storage are recommended, due to existing integrations with Azure services such as Azure Functions and Azure Data Factory.
- Modeling of restore scenarios, and how each will be implemented, including:
  - Account deleted
  - Database deleted
  - Container deleted
  - Specific data items deleted
  - Specific data items modified inappropriately
- Whether backups will be continuous or periodic
- How to handle changes (update or delete) to previously backed-up items
- For periodic custom backup, how frequently to run backups, and how adjustable to make this setting
- For periodic custom backup, how many backups to retain, and how adjustable to make this setting
- Implementation of periodic backup maintenance, such as deleting the oldest backups as they exit the retention window
- Added compute and storage will incur additional cost

The Cosmos DB documentation lists two options for implementing custom backup, using the [Cosmos DB change feed](https://docs.microsoft.com/azure/cosmos-db/change-feed) or using the [Azure Data Factory Connector for Cosmos DB](https://docs.microsoft.com/azure/data-factory/connector-azure-cosmos-db) (SQL API or API for MongoDB connectors only).

###### Custom Backup Option: Cosmos DB Change Feed

- Use the container change feed to write all data to a separate, protected storage facility
  - An [Azure Function](https://docs.microsoft.com/azure/cosmos-db/change-feed-functions) or other custom implementation which uses the [Change Feed Processor](https://docs.microsoft.com/azure/cosmos-db/change-feed-processor) will need to bind to the change feed and process items from the change feed into storage
- Either continuous or periodic (via batches) custom backups can be implemented with the Change Feed
- The Cosmos DB change feed does not yet reflect deletes (this is on the roadmap). A soft-delete pattern, as follows, can mitigate this short-term gap:
  - Application delete logic sets an item **boolean "is deleted" property** to true, instead of outright deleting the item
  - ... and sets the item's TTL to a very low value in the source container
  - The item with its updated soft delete setting is replicated by the change feed to protected storage
  - ... and the low TTL in the source container ensures the item is promptly deleted from the source container _after_ the item is added to the change feed and backed up
  - This pattern requires non-trivial implementation
  - This soft-delete pattern will be obsoleted by the roadmap full-fidelity change feed, which would also simplify a custom backup/restore implementation built on the Change Feed

###### Custom Backup Option: Azure Data Factory

- Use Azure Data Factory (ADF) to copy the data: connectors for Cosmos DB [SQL API](https://docs.microsoft.com/azure/data-factory/connector-azure-cosmos-db) and [API for MongoDB](https://docs.microsoft.com/azure/data-factory/connector-azure-cosmos-db-mongodb-api) are available
- Standard considerations for ADF orchestrations apply, including supported connectors and triggers
- ADF supports manual execution as well as the following triggers:
  - [Schedule](https://docs.microsoft.com/azure/data-factory/concepts-pipeline-execution-triggers#schedule-trigger)
  - [Tumbling window](https://docs.microsoft.com/azure/data-factory/concepts-pipeline-execution-triggers#tumbling-window-trigger)
  - [Event-based](https://docs.microsoft.com/azure/data-factory/concepts-pipeline-execution-triggers#event-based-trigger): Storage and Event Grid events are supported
- ADF is suitable for periodic custom backup implementations due to its batch-oriented orchestration; it is less suitable for continuous custom backup implementations, where many individual events per second may occur, due to orchestration execution overhead
- ADF supports [Azure Private Link](https://docs.microsoft.com/azure/data-factory/data-factory-private-link) for high network security scenarios

##### Azure Security Baseline

The Azure Security Baseline includes [control guidance for Cosmos DB Backup and Recovery](https://docs.microsoft.com/security/benchmark/azure/baselines/cosmos-db-security-baseline#backup-and-recovery). Three controls are documented:

- [BR-1: Ensure regular automated backups](https://docs.microsoft.com/security/benchmark/azure/baselines/cosmos-db-security-baseline#br-1-ensure-regular-automated-backups)
- [BR-3: Validate all backups including customer-managed keys](https://docs.microsoft.com/security/benchmark/azure/baselines/cosmos-db-security-baseline#br-3-validate-all-backups-including-customer-managed-keys)
- [BR-4, Mitigate risk of lost keys](https://docs.microsoft.com/security/benchmark/azure/baselines/cosmos-db-security-baseline#br-4-mitigate-risk-of-lost-keys)

Each of these is either a shared (customer and Microsoft) or customer responsibility.

#### Resource Protection at the Control Plane

Azure Cosmos DB resources are the *Cosmos DB account*, *databases within the account*, and *containers within databases*.

These resources are managed at the control plane, also called the management plane. Management operations include modifying or deleting any of these resources and its children.

The previous section described how to restore data from backup in the event of data corruption or loss. Data can be corrupted or lost due to incorrect data-plane operations, such as incorrect data changes or deletes, or due to control-plane operations such as incorrect deletes of a container, its database, or even the entire Cosmos DB account.

This section describes how to maintain continuity and high availability by protecting Cosmos DB resources from incorrect modification or deleting at the control plane. Protections include restricting control plane access, using Role-Based Access Control, and Resource Locks.

##### Restrict Control Plane Access

In Cosmos DB, there are two ways to authenticate:

1. Azure Active Directory identity
2. Cosmos DB keys or resource tokens

These two methods give access to different, partially overlapping capabilities.

![Cosmos DB Access Method Capabilities](https://docs.microsoft.com/azure/cosmos-db/media/how-to-restrict-user-data/operations.png "Cosmos DB Access Method Capabilities")

In many environments it will make sense to disable Resource management operations for connections using keys or resource tokens. This limits clients connecting with keys or resource tokens to data operations only, and permits finer-grained resource access control using Role-Based Access Control (RBAC) (see below) and/or Resource Locks (see below).

> Note: restricting control plane access via keys or resource tokens will disable control plane operations for clients using Cosmos DB SDKs, other clients accessing Cosmos DB via keys or resource tokens, or the Azure portal. **Ensure you test the effect of this change in relevant scenarios thoroughly BEFORE rolling out to production**, starting with the [Enablement Check List](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#check-list-before-enabling).

The `disableKeyBasedMetadataWriteAccess` setting can be configured via [ARM Template](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#set-via-arm-template), [Azure CLI](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#set-via-azure-cli), or [PowerShell](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#set-via-powershell).

This setting can also be configured via the Azure Built-In Policy [Azure Cosmos DB key based metadata write access should be disabled](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F4750c32b-89c0-46af-bfcb-2e4541a818d5).

##### Role-Based Access Control (RBAC)

Azure RBAC support in Azure Cosmos DB applies to account and resource control plane management operations. Administrators can create role assignments for users, groups, service principals or managed identities to grant or deny access to resources and operations on Cosmos DB resources.

There are several [Built-in RBAC Roles](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#built-in-roles) available for role assignments. [RBAC custom roles](https://docs.microsoft.com/azure/cosmos-db/role-based-access-control#custom-roles) can also be created, if specific combinations of [Cosmos DB Resource Provider operations](https://docs.microsoft.com/azure/role-based-access-control/resource-provider-operations#microsoftdocumentdb) and permissions are needed which are not addressed by the Built-in RBAC Roles.

Built-in RBAC roles include:

- [Cosmos DB Account Reader](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#cosmos-db-account-reader-role), which enables read-only access to Cosmos DB resource information
- [DocumentDB Account Contributor](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#documentdb-account-contributor), which enables management of Cosmos DB accounts including keys and role assignments, but does not enable data-plane access
- [Cosmos DB Operator](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#cosmos-db-operator), which is similar to DocumentDB Account Contributor, but without the ability to manage keys and role assignments

> Note: If control plane access is not restricted with `disableKeyBasedMetadataWriteAccess`, then clients can connect with account keys and still perform control plane operations.

##### Resource Locks

Azure Cosmos DB resources (accounts, databases, and containers) can be protected against incorrect modification or deleting with [Resource Locks](https://docs.microsoft.com/azure/cosmos-db/resource-locks). Resource Locks can be set at the account, database, or container level. A Resource Lock set at on a resource will be inherited by the resource's children. For example, a Resource Lock set on the Cosmos DB account will be inherited by all databases and containers in the account, and a Resource Lock set on a database will be inherited by containers in that database.

Resource Locks **only** apply to control plane operations. They do **not** prevent data plane operations, including creating, changing, or deleting data.

> Note: If control plane access is not restricted with `disableKeyBasedMetadataWriteAccess`, then clients can connect with account keys and still perform control plane operations. Resource locks will NOT block control plane operations if `disableKeyBasedMetadataWriteAccess` was not set on the account.

Resource Locks can be set via [ARM Template](https://docs.microsoft.com/azure/cosmos-db/resource-locks#template), [Azure CLI](https://docs.microsoft.com/azure/cosmos-db/resource-locks#azure-cli), or [PowerShell](https://docs.microsoft.com/azure/cosmos-db/resource-locks#powershell).

#### Resource Recovery

In the event Cosmos DB data or resources are incorrectly modified or deleted, they can be recovered. The process differs for Periodic vs. Continuous backup (see below). Either way, it is strongly recommended to practice recovery operations in advance, on non-production resources and data, as part of standard continuity preparations.

##### Periodic Backup

If Periodic Backup is used, then a [Support ticket must be opened to request the recovery of data or resources](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore#request-restore).

The recovery process will create a new Cosmos DB account to hold the restored resources and data. This new Cosmos DB account will default to a system-generated name of `<Azure_Cosmos_account_original_name>-restored*n*`, where *n* is an integer that starts at 1 and increments by 1 for each attempted recovery. However, in the event an entire Cosmos DB account was deleted, the recovery process can create an account with the deleted account's name.

The full list of [Recovery Considerations](https://docs.microsoft.com/azure/cosmos-db/configure-periodic-backup-restore#considerations-for-restoring-the-data-from-a-backup) should be reviewed in advance as part of standard Continuity preparations.

##### Continuous Backup

If Continuous Backup is used, then data and resources can be restored via self-service, to any point in time within the last 30 days.

Self-service restore operations can be completed with [the Azure portal](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-portal), [Azure CLI](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-cli), [PowerShell](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-account-powershell), or [ARM Template](https://docs.microsoft.com/azure/cosmos-db/restore-account-continuous-backup#restore-arm-template) with `createMode` set to **Restore**.

### Azure Front Door (AFD)

#### High Availability

AFD is a global Azure resource. An AFD configuration is deployed globally to all [AFD edge locations](https://docs.microsoft.com/azure/frontdoor/edge-locations-by-region).

In addition to global deployments, AFD provides high availability since updates to AFD configurations included routes and backend pools are seamless and will not cause any downtime during deployment. Certificate updates will only cause downtime if AFD is switched between "AFD Managed" and "Use your own cert".

AFD auto-rotates "AFD Managed" certificates at least 60 days ahead of certificate expiration to protect against expired certificate errors. If "Use your own cert" self-managed certificates are used, updated certificates should be deployed no later than 24 hours prior to expiration of the existing, expiring certificate being replaced, otherwise clients may receive expired certificate errors which may be considered to lower availability.

##### DDoS Protection

Distributed Denial of Service (DDoS) attacks can render a targeted resource unavailable by overwhelming the resource's ability to respond correctly to all traffic, including legitimate client traffic. This will reduce the application's perceived overall availability and continuity.

AFD is protected by Azure DDoS Protection Basic, which is integrated into AFD by default. This provides always-on traffic monitoring and real-time mitigation, and also defends against common Layer 7 DNS query floods and Layer 3/4 volumetric attacks. These protections help to maintain Azure Front Door availability to respond correctly to client traffic even if targeted by a DDoS attack.

##### Protocol Blocking

AFD only accepts traffic on HTTP and HTTPS protocols, and will only process requests with a known `Host` header. This helps mitigate volumetric attacks spread across protocols and ports, as well as DNS amplification and TCP poisoning attacks.

##### Capacity

AFD is globally distributed at massive scale and has been proved to handle hundreds of thousands of requests per second for many customers.

##### Web Application Firewall

AFD's Web Application Firewall (WAF) mitigates a number of types of attacks to preserve availability. Capabilities include firewall rulesets to protect against various common attacks, geo-filtering, address blocking, rate limiting, and signature matching.

### Azure Monitor

Azure Monitor supports three types of observability data: Logs, Metrics, and Distributed Traces. AlwaysOn stores Logs and Metrics for global resources.

Logs are stored in Azure Monitor Logs (previously called Log Analytics) workspaces based on [Azure Data Explorer](https://docs.microsoft.com/azure/data-explorer/). Log queries, e.g. to drive dashboards, workbooks or other reporting or visualization tools, are stored in query packs and can be shared across subscriptions.

Metrics are stored in an internal time-series database. For most Azure resources, [platform metrics are stored](https://docs.microsoft.com/azure/azure-monitor/essentials/data-platform-metrics#retention-of-metrics) for 93 days; certain Virtual Machine guest OS metrics may be stored between 31 days and two years. Metric collection is configured through resource Diagnostic settings. Many [Azure Built-In Policies](https://docs.microsoft.com/azure/azure-monitor/policy-reference) are available to ensure deployed resources are configured to send metrics to an Azure Monitor instance.

#### High Availability

Azure Monitor is enabled for an Azure subscription when the subscription is created. Azure Monitor for Logs and Azure Application Insights resources are created as needed to add data collection and querying capabilities.

[Azure Monitor Logs Dedicated Clusters](https://docs.microsoft.com/azure/azure-monitor/logs/logs-dedicated-clusters) are a deployment option which enables Availability Zones for protection from zonal failures in supported Azure regions. Note that Dedicated Clusters require a minimum daily data ingest commitment.

Azure Monitor for Logs resources, including underlying log and metrics storage, are deployed into a specified Azure region. To protect against regional unavailability, the following configurations should be considered.

##### Multiple Redundant Workspaces

To protect against loss of data from unavailability of an Azure Monitor for Logs workspace, resources can be configured with multiple Diagnostics configurations. Each Diagnostic configuration can target metrics and logs at a separate Azure Monitor for Logs workspace. **Note that each additional Azure Monitor for Logs workspace will incur added cost**. This configuration can be considered for situations where it is extremely critical to protect against Azure Monitor data loss or unavailability.

The redundant Azure Monitor for Logs workspaces can be deployed into the same Azure region, or into separate Azure regions for greater protection against regional downtime. Note, however, that sending logs and metrics from an Azure resource to an Azure Monitor for Logs workspace in a different region will incur inter-region data egress costs, network latency, and that some Azure resources may require an Azure Monitor for Logs workspace in the same region as the resources.

##### Workspace Data Export

Azure Monitor Logs workspace data [can be exported to Azure Storage or Azure Event Hubs on a continuous, scheduled, or one-time basis](https://docs.microsoft.com/azure/azure-monitor/logs/logs-data-export) (in preview as of September 2021). Data export protects against possible Azure Monitor Logs data loss due to zonal or regional unavailability. Additionally, data export enables retention of data past the Azure Monitor service data retention maximum.

The export destinations are Azure Storage or Azure Event Hub. Data export destinations must be in the same Azure region as the Azure Monitor Logs workspace. Other applicable [limitations](https://docs.microsoft.com/azure/azure-monitor/logs/logs-data-export?tabs=portal#limitations) should be reviewed for a data export scenario.

> Note: specific Azure Monitor Logs tables are supported for data export. Consult the [list of supported tables](https://docs.microsoft.com/azure/azure-monitor/logs/logs-data-export#supported-tables). More tables may be added over time.

Azure Storage can be configured for [redundancy levels](https://docs.microsoft.com/azure/storage/common/storage-redundancy) including zonal, regional, or geo-zonal. Using Azure Storage with one of these redundancy levels protects Azure Monitor Logs data against loss due to zonal or regional unavailability. Data export to Azure Storage stores the data in .json files.

Azure Event Hubs supports Availability Zones (AZs) for zonal redundancy in Azure regions with AZs. Azure Event Hubs also provides failover between regions if the primary region becomes unavailable, but failover replicates only metadata, not data between regions. Further, Azure Monitor Logs requires an Event Hub data export destination to be in the same region as the Azure Monitor Logs workspace, so Azure Event Hubs geo-disaster recovery is not applicable for this scenario.

Azure Event Hubs can be configured to [capture data into Azure Blob Storage or Azure Data Lake Storage](https://docs.microsoft.com/azure/event-hubs/event-hubs-capture-overview). Event Hub Capture to Azure Storage or Data Lake Storage stores the captured data in .avro files.

In addition to Event Hubs capture, data can also be processed from Event Hubs by [Azure Stream Analytics](https://docs.microsoft.com/azure/event-hubs/process-data-azure-stream-analytics), or by a client using the [Event Processor SDK](https://docs.microsoft.com/azure/event-hubs/event-processor-balance-partition-load). Both of these scenarios enable additional data processing and enrichment as well as flexibility of eventual data storage, but both require additional implementation and management effort.

Event Hubs can be deployed as a single-tenant, Dedicated-tier Event Hubs cluster for high throughput and a 99.99% SLA, whereas Basic and Standard tiers provide a 99.95% SLA.

##### Limits

Azure Monitor Logs has [user query throttling limits](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#user-query-throttling) which may appear as lowered availability to clients, such as dashboards or other capabilities which depend on Azure Monitor Logs queries. These limits include:

- Five concurrent queries per user. If five queries are already running, additional queries are placed in a per-user concurrency queue. When a running query ends, the next query will be de-queued and run.
- Time in concurrency queue. If a query sits in the concurrency queue for over three minutes, it will be terminated and a 429 error code returned.
- Concurrency queue depth limit. The concurrency queue is limited to 200 queues. Additional queries will be rejected with a 429 error code.
- Query rate limit. There is a per-user limit of 200 queries per 30 seconds across all workspaces.

#### Resource Recovery

In addition to protecting Azure Monitor data from loss through Data Export as discussed above, queries can also be protected and recovered in the event of regional or Azure Monitor Logs workspace unavailability.

Query Packs are Azure Resource Manager resources which store Azure Monitor Logs queries. Query Packs contain queries as JSON, are deployable through the Microsoft.Insights REST API, and should be externally stored and protected similar to other infrastructure-as-code assets. If an Azure Monitor for Logs workspace must be re-created or the Query Pack is incorrectly changed or deleted, the Query Pack should be re-deployed from the externally stored definition.

### General Considerations

The following considerations apply in addition to similar resource type-specific notes above.

#### Policy

Azure Policy should be adopted for resource configurations intended to optimize for high availability. Both Built-in and Custom policy definitions are supported. The use of Azure Policy aligns with [Enterprise Scale guidance](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/security-governance-and-compliance#plan-for-governance) and standardizes governance and compliance, shifting these out of individual applications and into organizational contexts such as subscriptions or Management Groups.

#### Resource Locking

Azure [resources can be locked](https://docs.microsoft.com/azure/azure-resource-manager/management/lock-resources) to prevent them from being modified or deleted. Locking resources protects Continuity in production environments by preventing incorrect resource changes or deletes.

Using resource locks increases management overhead ongoing. For example, deployment pipelines or processes must remove locks, perform deployment steps, then re-create locks. The additional management overhead should be considered when validating resource lock usage.

Appropriate Role Based Access Control (RBAC) management with role assignments that minimize the ability to change or delete resources is necessary whether or not resource locks are used. This will likely be sufficient to protect resources from incorrect changes or deletes.

#### Resource Recovery

If an Azure resource is deleted incorrectly, an Azure Support case can be opened to attempt recovery of the deleted resource. This may apply if the resource contained state or data that it is critical to recover.

For stateless resources or resources which can be entirely configured from deployment, such as Azure Front Door and its back ends/origins, re-deployment will generally result in an operational resource faster than a Support process to attempt recovery of the deleted resource.

---

|Previous Page|Next Page|
|:--|:--|
|[Security](./Security.md) |[AlwaysOn Reference Implementation](https://github.com/Azure/AlwaysOn/blob/main/docs/reference-implementation/README.md)

---

|Design Guidelines|
|--|
|[How to use the AlwaysOn Design Guidelines](./README.md)
|[AlwaysOn Design Principles](./Principles.md)
|[AlwaysOn Design Areas](./Design-Areas.md)
|[Application Design](./App-Design.md)
|[Application Platform](./App-Platform.md)
|[Data Platform](./Data-Platform.md)
|[Health Modeling and Observability](./Health-Modeling.md)
|[Deployment and Testing](./Deploy-Testing.md)
|[Networking and Connectivity](./Networking.md)
|[Security](./Security.md)
|[Operational Procedures](./Operational-Procedures.md)

---

[AlwaysOn - Full List of Documentation](/docs/README.md)
