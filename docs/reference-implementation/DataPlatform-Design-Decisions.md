# Data Platform Design Decisions

The Azure Mission-Critical application data access pattern has the following characteristics:

- **Read pattern**:
  - Point reads, e.g. fetching a single record. These use item ID and partition key directly for maximum optimization (1 RU per request).
  - List reads, e.g. getting catalog items to display in a list. `FeedIterator` with limit on number of results is used.
- **Write pattern**:
  - Small writes e.g. queries which usually insert a single or a very small number of records in a transaction.
- Designed to handle high traffic from end-users with the ability to scale to handle traffic demand in the order of millions of users.
- **Small payload** or dataset size - usually in order of KBs.
- Low response time (in order of milliseconds).
- Low latency (in order of milliseconds).

The OLTP nature of the access pattern of Azure Mission-critical has a bearing on the choice of architectural characteristics and must be considered while choosing backend datastores. The key architectural characteristics are:

- Performance
- Latency
- Responsiveness
- Scalability
- Durability
- Resiliency
- Security

Based on these characteristics, Azure Mission-critical uses the following data stores:

- Cosmos DB to serve as the main backend database.
- Event Hubs for messaging capabilities.

> **Note**: From data platform capabilities perspective, the current reference implementation of Azure Mission-Critical focuses on the operational data store. In future, we plan to update Azure Mission-Critical guidance to include analytics capabilities. In the meantime, we encourage readers to refer to [Enterprise Scale Analytics](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/data-management/enterprise-scale-landing-zone) guidance for enabling analytics at scale on Azure.

## Database

**[Azure Cosmos DB](https://azure.microsoft.com/services/cosmos-db/)** was chosen as the main database as it provides the crucial ability of multi-region writes: each stamp can write to the Cosmos DB replica in the same region with Cosmos DB internally handling data replication and synchronization between regions.

Azure Mission-critical is a cloud-native application. Its data model does not require features offered by traditional relational databases (e.g. entity linking across tables with foreign keys, strict row/column schema, views etc.).

The SQL API of Cosmos DB is being used as it provides the most features and there is no requirement for migration scenario (to or from some other database like MongoDB).

The reference implementation uses Cosmos DB as follows:

- **Consistency level** is set to the default "Session consistency" as the most widely used level for single region and globally distributed applications. Azure Mission-critical does not use weaker consistency with higher throughput because the asynchronous nature of write processing doesn't require low latency on database write.

- **Partition key** is set to `/id` for all collections. This decision is based on the usage pattern which is mostly "writing new documents with random GUID as ID" and "reading wide range of documents by ID". Providing the application code maintains its ID uniqueness, new data will be evenly distributed into partitions by Cosmos DB.

- **Indexing policy** is configured on collections to optimize queries. To optimize RU cost and performance a custom indexing policy is used and this only indexes properties used in query predicates. For example, the application doesn't use the comment text field as a filter in queries and so it was excluded from the custom indexing policy.

*Example of setting indexing policy in Terraform:*

```
indexing_policy {

  excluded_path {
    path = "/description/?"
  }

  excluded_path {
    path = "/comments/text/?"
  }

  included_path {
    path = "/*"
  }

}
```

- **Database structure** stores related data as single documents.

- **In application code**, the SDK is configured as follows:
  - Use Direct connectivity mode (default for .NET SDK v3) as this offers better performance because there are fewer network hops compared to Gateway mode which uses HTTP.
  - `EnableContentResponseOnWrite` is set to `false` to prevent the Cosmos DB client from returning the resource from Create, Upsert, Patch and Replace operations to reduce network traffic and because this is not needed for further processing on the client.
  - Custom serialization is used to set the JSON property naming policy to `JsonNamingPolicy.CamelCase` (to translate .NET-style properties to standard JSON-style and vice-versa) and the default ignore condition to ignore properties with null values when serializing (`JsonIgnoreCondition.WhenWritingNull`).

The Azure Mission-critical reference implementation leverages the native backup feature of Cosmos DB for data protection. [Cosmos DB's backup feature](https://docs.microsoft.com/azure/cosmos-db/online-backup-and-restore) supports online backups and on-demand data restore.

> **Note:** In practice, most workloads are not purely OLTP. There is an increasing demand for real-time reporting, such as running reports against the operational system. This is also referred to as HTAP (Hybrid Transactional and Analytical Processing). Cosmos DB supports this capability via [Azure Synapse Link for Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/synapse-link-use-cases).

## Messaging bus

**[Azure Event Hubs](https://docs.microsoft.com/azure/event-hubs/event-hubs-about)** service is used for the asynchronous messaging between the API service (`CatalogService`) and the background worker (`BackgroundProcessor`). It was chosen over alternative services like Azure Service Bus because of its high throughput support and because Azure Mission-critical does not require features like Service Bus' in-order delivery.

Event Hubs offers zone redundancy in its Standard SKU, whereas Service Bus requires Premium tier for this reliability feature.

The only event processor in the Azure Mission-critical reference implementation is the **BackgroundProcessor** service which captures and processes events from all Event Hubs partitions.

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

Besides standard user flow messages (database CRUD operations), there are also health check messages identified by the `HEALTHCHECK=TRUE` metadata value. Currently health check messages are dropped and not processed further.

If a message isn't a health check and doesn't contain `action`, it's also dropped.

See [BackgroundProcessor](/src/app/AlwaysOn.BackgroundProcessor/README.md) for more details about the implementation.

> **Note**: A messaging queue is not intended to be used as a persistent data store for an long periods of time. Event Hubs supports [Capture feature](https://docs.microsoft.com/azure/event-hubs/event-hubs-capture-enable-through-portal) which allows an Event Hub to automatically write a copy of messages to a linked Azure Storage account. This keeps utilization of an Event Hubs queue in-check but it also serves as a mechanism to backup messages.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
