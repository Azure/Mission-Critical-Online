# Data Platform Design Decisions

The Azure Mission-Critical application data access pattern has the following characteristics:

- Read pattern - Point reads e.g. queries which fetch a single record. These queries have a "WHERE" clause defined so that a single row is selected for reads.
- Write pattern - Small writes e.g. queries which usually insert a single or a very small number of records in a transaction.
- Designed to handle high traffic from end-users with the ability to scale to handle traffic demand in the order of millions of users
- Payload or dataset size - small (usually in order of KB)
- Data freshness - This stores the latest transactional data with a limited history
- Low response time (in order of milli-seconds)
- Low Latency (in order of milli-seconds)

The OLTP nature of the access pattern of Azure Mission-Critical has a bearing on the choice of architectural characteristics and must be considered while choosing backend datastores. The key architectural characteristics are:

- Performance
- Latency
- Responsiveness
- Scalability
- Durability
- Resiliency
- Security

Based on these characteristics, Azure Mission-Critical uses the following data stores:

- Cosmos DB to serve as the main backend database.
- Event Hubs for messaging capabilities.

> **Note** - From data platform capabilities perspective, the current reference implementation of Azure Mission-Critical focuses on the operational data store. In future, we plan to update Azure Mission-Critical guidance to include analytics capabilities. In the meantime, we encourage readers to refer to [Enterprise Scale Analytics](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/data-management/enterprise-scale-landing-zone) guidance for enabling analytics at scale on Azure.

## Designing a database

When you deploy Cosmos DB it consists of one account. Each account can have multiple databases and every database can have one to many containers. CosmosDBs execution capacity unit us Request Units (RU's). RU usage can be dedicated to the Database Scope to be shared by the underlying Containers, or can be dedicated to a single Container scope. Independent from whether you consume RU's on Database wide or Container level, when assigning RU usage behavior there two options  you can either assign a fixed number of Request Units (RU's)  or you choose to let Microsoft manage the Autoscaling between customer decided minimum n-RU's and maximum n/10-RU's.
If you chose the latter the infrastructure supporting the maximum capacity is created upfront. If you chose the former the infrastructure gets provisioned by the manual scale operations that may be performed upon need. In cosmos DB the effect of scale up on underlying infrastructure is irreversible. Cosmos DB scales by adding new compute nodes to the existing cluster to support required data size or RU capacity. The given RU capacity is always equally shared by the existing compute nodes. For more information on scaling CosmosDB you can refer to the this article [Background on scaling RU's](https://docs.microsoft.com/azure/cosmos-db/scaling-provisioned-throughput-best-practices#background-on-scaling-rus) on Microsoft CosmosDB documentation.

When creating a new database and you don't know the load, it is recommended to monitor this closely and adjust If you have somewhat an idea you can use [CosmosDB Capacity Calculator](https://cosmos.azure.com/capacitycalculator/) to have a rough estimate as a better chosen starting point. Starting small and then scaling up upon need by monitoring the application can be is a good practice.

Cosmos DB exposes a set of API's. Each API has different functionality and SDK's.

* Core(SQL) API
This API stores data in document format. It offers the best end-to-end experience as we have full control over the interface, service, and the SDK client libraries. Any new feature that is rolled out to Azure Cosmos DB is first available on SQL API accounts.
* API for MongoDB
This API stores data in a document structure, via BSON format. It is compatible with MongoDB wire protocol(up to 4.0).
* Cassandra API
This API stores data in column-oriented schema. Apache Cassandra is a highly distributed, horizontally scaling approach to storing large volumes of data while offering a flexible approach to a column-oriented schema.
* Gremlin API
This API allows users to make graph queries and stores data as edges and vertices. Use this API for scenarios involving dynamic data, data with complex relations, data that is too complex to be modeled with relational databases, and if you want to use the existing Gremlin ecosystem and skills.
* Table API
This API stores data in key/value format.

The remainder of this article will focus on the Core SQL API.

## Distribution

Each database consists of n number of Container. Each container can have one or many logical partitions and physical partitions hosting the logical partitions . Physical partitions are the nodes Cosmos DB is built on and are automatically provisioned as your data size or throughput grows. Each physical partition can contain up tos 20 GB of data and has a maximum throughput capacity of 10k RU's. Each physical partition can have  n number of logical partitions, but a logical partition can not grow larger than a physical partition, hence 1 logical partition can be hosted only on 1 physical partition while 1 physical partition can host n logical partitions. When creating new containers if the given initial RU is more than around 8K the CosmosDB gets provisioned as more than 1 physical partition, where each partition can have an RU value between 4k & 6k RU's and this allow you to grow to 10k without having to reshuffle.  So if your CosmosDB has only 1 physical partition it can grow to 10K RUs without provisioning new nodes, but if you create your CosmosDB starting with 10K RU's you will end up with at least 2 physical partition each using 5K RU's and the CosmosDB  can scale up to 20K RU's without any new node provisioning.

### Selecting a partition key

When designing your Cosmos DB it is essential to chose the right partition key to be able to achieve performance and scalability. You have three options; Single value key, Synthetic key or Hierarchial keys(this feature is in preview). Cosmos DB uses the hash of the partition key value to determine which logical and physical partition the data lives on. Ideally you want to have an even distribution of logical partitions  by size and read requests as possible, with documents and RU usage spread evenly across partitions.
The most efficient way to retrieve a document is by using the documents unique ID and the partition key. This will result in a "point read". For read heavy workloads choose a key that is part of the filter. To add more cardinality to our key, we can use a synthetic key, combining multiple
attributes. which would require the queries to do the the same combination operation. The cons of building a synthetic key is that you can not benefit from it for individual pieces of the synthetic key.

```sql
SELECT * FROM n WHERE "Partition_Key" = 123 
```

Multi item transactions has to be performed on the same logical partition.

### Hierarchical partition key

With hierarchical partition keys, partition your container with up to three levels of partition keys.

```json
|- PartitionKey1
    |- PartitionKey2
        |- PartitionKey3
```

Using hierarchical partition keys, it is now possible to retrieve data that spans multiple physical partitions.

At the same time, the queries will still be efficient. All queries that target a single tenant will be routed to the subset of partitions the data is on, avoiding the full cross-partition fanout query that would be required when using a synthetic partition key strategy.

* Hierarchical partition keys are in preview *

### Design Recommendations

* Select a partition key that will ensure your logical partition always stay smaller than the physical partition limits.
* Partition keys should be immutable and have a high cardinality.
* Use hierarchial distribution keys for large datasets to get an even distribution of documents and throughput across the logical and physical partitions of your container.

## Document structure

### No-SQL denormalization

In these two examples you’ll see denormalization of the data model. Option 1 has separated transactions adn use a weak relational link between the entities using the unique Id. The second (denormalized) example doesn’t need a second lookup in the client container. You can just fetch the document and have the transactions embedded in the document.
With the denormalized model each container can be scaled independently.

#### Option 1 - two separate containers

Client document:

```json
{
    "clientId": "",
    "wallet": [
        {
            "walletId": "",
            "bookBalance": "",
            "reservedBalance": "",
            "subwallet": [
                {
                    "subwalletId": "",
                    "balance": ""
                }
            ]
        }
    ],
    "card": [
        {
            "cardNumber": ""
        }
    ]
}
```

Transaction document:

```json
{
    "transactionId":"",
    "transactionData":"",
    "cardNumber":"",
    "walletId":"",
    "subwalletId":""
}
```

#### Option 2 - Nested documents

The two documents in the previous example are merged into a nested document. This can be done to ensure they are both in the same logical partition. Be aware that this can create very large documents and reduce performance on CRUD operations. Every time you update anything og add a new nested sub-document like a transaction you have to fetch the entire document.

```json
{
    "clientId": "",
    "wallet": [
        {
            "walletId": "",
            "bookBalance": "",
            "reservedBalance": "",
            "subwallet": [
                {
                    "subwalletId": "",
                    "balance": "",
                    "transaction": [
                        {
                            "transactionId": "",
                            "transactionData": "",
                            "cardNumber": ""
                        }
                    ]
                }
            ]
        }
    ],
    "card": [
        {
            "cardNumber": ""
        }
    ]
}
```

### Design recommendations

* Consider the size of each document and the nesting level. Avoid large documents.
* Optimize document structure for query patterns.
* Denormalization is not always the best option.

## ACID transactions

ACID (Atomicity, Consistency, Isolation, Durability) is a set of properties of database transactions intended to guarantee data validity. Cosmos DB supports full ACID compliant transactions with snapshot isolation. All the database operations a logical partition are transactionally executed within the database engine that is hosted by the replica of the partition. These operations include all CRUD operations of one or multiple items. Stored procedures, triggers, UDFs, and merge procedures are ACID transactions with snapshot isolation across all items within the same logical partition. During the execution, if the program throws an exception, the entire transaction is aborted and rolled-back.

### Design recommendation

* ACID transactions are confined to a logical partition. All data managed by the transaction has to reside in the same logical partition.

### Design considerations

* An alternative solution if the application needs to update multiple containers can be to listen to Cosmos DB change feed and create an event trigger to update the different containers. This will involve multiple chained transactions.

## Indexing

All fields in a document are indexed automatically. Cosmos DB has 3 different types of indexes.

* Range index
  * Automatically added to all objects
* Spatial index
  * Used for Geospatial data
* Composite
  * Used for Complex filters

Cosmos DB is schema-less and index all your data regardless of the data model. This is the Range-index.

You can define custom indexing policies for your containers. This allows you to improve query performance and consistency. Index policies are defined as the example below with including and excluding paths. You can also specify document attributes, data types and ordering sequence.

```csharp
IndexingPolicy indexingPolicy = new IndexingPolicy
{
    IndexingMode = IndexingMode.Consistent,
    Automatic = true,
    IncludedPaths =
    {
        new IncludedPath
        {
            Path = "/*"
        }
    },
    ExcludedPaths =
    {
        new ExcludedPath
        {
            Path = "/ignore"
        }
    }
};
```

### Design recommendations

* Use the metrics analysis with information about storage and throughput to optimize your indexing policies.
* Index policies are applied to an entire container, but will be executed on each partition.

## Consistency and availability

| Region(s) | Mode | Consistency | RPO | RTO |
|:-----------|:--------|--------|--------------|--------|
| 1 | Any | Any | < 240 minutes | < 1 week |
| > 1 | Single Write | Session, Consistent Prefix, Eventual | < 15 minutes | < 15 minutes |
| > 1 | Single Write | Bounded Staleness | K & T* | < 15 minutes |
| > 1 | Single Write | Strong | 0 | < 15 minutes |
| > 1 | Multi Write | Session, Consistent Prefix, Eventual | < 15 minutes | 0 |
| > 1 | Multi Write | Bounded Staleness | K & T* | 0 |
| > 1 | Single Write | Strong | N/A | N/A |

*Number of K updates of an item or T time. In >1 regions, K=100,000 updates or T=5 minutes.

## Synapse Link

Analytical workloads are very different from transactional workloads and require different tools to store and query the data.

```sql
SELECT * FROM A UNION SELECT * FROM B
vs
SELECT A FROM N WHERE id = 123
```

When setting up Synapse Link for Cosmos DB it has an independent TTL - Time to live, Analytical data can live forever and the more expensive transactional data can have a shorter retention.

* TTL is set at container level, each container can have different TTL's.

* The data exported to the data lake using a highly compressed Parquet format - up to 90% reduction in size.
* No cost of replicating the data and no impact on the transactional store, no RU's used
* Cheaper to run queries in Synapse than in CosmosDB
* Spark connector to write data back to CosmosDB
* Data is synced within 2 min, all CRUD operations are performed on the parquet files
* Automatic Schema inference
  * Schema inference type can only be set at creation time and not changed
  * Well-Defined schema - Data type pr column. One column for each entity. "wrong" type represented as NULL ( you loose data of wrong type.
  * Full-Fidelity - Multiple columns (pr data type) for each entity. Missing data represented as NULL

Analytical store will be available in all locations Cosmos DB is provisioned.
Synapse will default to the primary region, but you can change to any region available

### Custom partitioning

Custom partitioning on Synapse Link created using Synapse Spark - Partitioned Store

* Only on SQL atm (MongoDB soon)
* Jobs are schedule
* Improved query performance.
* Can create multiple partition stores optimized for each query plan
* Partition pruning - Now you scan less data and can save cost pr query
* Default Synapse Link with slow data ingestion gets fragmented, partitioning defragments it.
* Reads and updates the Delta only
* Customer define frequency, path  in ADLS, partition key
* Define number of records pr file, recommend creating bigger files ~2 mill
* Any property in a nested JSON can be used as a partition key
* The first document defines the schema.
  * If your first doc is wrong or bugged, it has to be removed for a new schema to be created.
  

## Reference implementation Database design

**[Azure Cosmos DB](https://azure.microsoft.com/services/cosmos-db/)** was chosen as the main database as it provides the crucial ability of multi-region writes: each stamp can write to the Cosmos DB replica in the same region with Cosmos DB internally handling data replication and synchronization between regions.

Azure Mission-Critical is a cloud-native application. Its data model does not require features offered by traditional relational databases (e.g. entity linking across tables with foreign keys, strict row/column schema, views etc.).

The SQL API of Cosmos DB is being used as it provides the most features and there is no requirement for migration scenario (to or from some other database like MongoDB).

The reference implementation uses Cosmos DB as follows:

- **Consistency level** is set to the default "Session consistency" as the most widely used level for single region and globally distributed applications. Azure Mission-Critical does not use weaker consistency with higher throughput because the asynchronous nature of write processing doesn't require low latency on database write.

- **Partition key** is set to `/id` for all collections. This decision is based on the usage pattern which is mostly "writing new documents with random GUID as ID" and "reading wide range of documents by ID". Providing the application code maintains its ID uniqueness, new data will be evenly distributed into partitions by Cosmos DB.

- **Indexing policy** is configured on collections to optimize queries. To optimize RU cost and performance a custom indexing policy is used and this only indexes properties used in query predicates. For example, the application doesn't use the winning player name field as a filter in queries and so it was excluded from the custom indexing policy.

*Example of setting indexing policy in Terraform:*

```
indexing_policy {

  excluded_path {
    path = "/winningPlayerName/?"
  }

  excluded_path {
    path = "/playerGestures/gesture/?"
  }

  excluded_path {
    path = "/playerGestures/playerName/?"
  }

  included_path {
    path = "/*"
  }

}
```

- **Database structure** follows basic NoSQL principles and stores related data as single documents.
  - Application code gets the `playerName` information from AAD and stores it in the database instead of querying AAD each time.
  - Leaderboard is generated on-demand and persists in the database (instead of recalculating on every request) as this action can be a database-heavy operation.

- **In application code**, the SDK is configured as follows:
  - Use Direct connectivity mode (default for .NET SDK v3) as this offers better performance because there are fewer network hops compared to Gateway mode which uses HTTP.
  - `EnableContentResponseOnWrite` is set to `false` to prevent the Cosmos DB client from returning the resource from Create, Upsert, Patch and Replace operations to reduce network traffic and because this is not needed for further processing on the client.
  - Custom serialization is used to set the JSON property naming policy to `JsonNamingPolicy.CamelCase` (to translate .NET-style properties to standard JSON-style and vice-versa) and the default ignore condition to ignore properties with null values when serializing (`JsonIgnoreCondition.WhenWritingNull`).

The Azure Mission-Critical reference implementation leverages the native backup feature of Cosmos DB for data protection. [Cosmos DB's backup feature](https://docs.microsoft.com/azure/cosmos-db/online-backup-and-restore) supports online backups and on-demand data restore.

> Note - In practice, most workloads are not purely OLTP. There is an increasing demand for real-time reporting, such as running reports against the operational system. This is also referred to as HTAP (Hybrid Transactional and Analytical Processing). Cosmos DB supports this capability via [Azure Synapse Link for Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/synapse-link-use-cases).

## Messaging bus

**[Azure Event Hubs](https://docs.microsoft.com/azure/event-hubs/event-hubs-about)** service is used for the asynchronous messaging between the API service (CatalogService) and the background worker (BackgroundProcessor). It was chosen over alternative services like Azure Service Bus because of its high throughput support and because Azure Mission-Critical does not require features like Service Bus' in-order delivery.

Event Hubs offers Zone Redundancy in its Standard SKU, whereas Service Bus requires Premium tier for this reliability feature.

The only event processor in the Azure Mission-Critical reference implementation is the **BackgroundProcessor** service which captures and processes events from all Event Hubs partitions.

Every message needs to contain the `action` metadata property which directs the route of processing:

```csharp
// `action` is a string:
//  - AddCatalogItem
//  - AddComment
//  - AddRating
//  - DeleteObject
switch (action)
{
    case Constants.AddCatalogItemActionName:
        await AddCatalogItemAsync(messageBody);
        break;
    case Constants.AddCommentActionName:
        await AddItemCommentAsync(messageBody);
        break;
    case Constants.AddRatingActionName:
        await AddItemRatingAsync(messageBody);
        break;
    case Constants.DeleteObjectActionName:
        await DeleteObjectAsync(messageBody);
        break;
    default:
        _logger.LogWarning("Unknown event, action={action}. Ignoring message", action);
        break;
}
```

Besides standard user flow messages (database CRUD operations),there are also health check messages identified by the `HEALTHCHECK=TRUE` metadata value. Currently health check messages are dropped and not processed further.

If a message isn't a health check and doesn't contain `action`, it's also dropped.

See [BackgroundProcessor](/src/app/AlwaysOn.BackgroundProcessor/README.md) for more details about the implementation.

> **Note** - A messaging queue is not intended to be used as a persistent data store for an long periods of time. Event Hubs supports [Capture feature](https://docs.microsoft.com/azure/event-hubs/event-hubs-capture-enable-through-portal) which enables an Event Hub to automatically write a copy of messages to a linked Azure Storage account. This keeps utilization of an Event Hubs queue in-check but it also serves as a mechanism to backup messages.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
