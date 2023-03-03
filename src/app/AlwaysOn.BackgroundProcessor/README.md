# Background Processor

The worker application is based on the [.NET Core Worker Service](https://learn.microsoft.com/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-5.0&tabs=visual-studio) template, using the Worker SDK which is designed for background task processing.

```xml
<Project Sdk="Microsoft.NET.Sdk.Worker">
```

There's no UI or API as the worker is constantly listening for new events on the message queue.

## Configuration

Refer to [CatalogService configuration](../AlwaysOn.CatalogService/README.md#Configuration) for details of the implementation.

Apart from the configuration settings which are common between components, such as Cosmos DB connection settings, the following settings are used exclusively by the BackgroundProcessor:

- `BackendReaderEventHubConnectionString`: Connection string with `Listen` permissions to the Event Hub.
- `BackendReaderEventHubConsumergroup`: Consumer group in the Event Hub to be used exclusively by the BackgroundProcessor.
- `BackendStorageConnectionString`: Connection string to the storage account which is used for checkpointing, partition ownership management and poison message storage.
- `BackendCheckpointBlobContainerName`: Name of the container on the aforementioned blob storage account.
- `BackendCheckpointLoopSeconds`: Controls how often checkpointing on blob storage happens. The more frequent, the more overhead this creates and will slow down processing. Longer periods, however, can make for more duplicate processing on restart or partition ownership change.
- `BackendStoragePoisonMessagesTableName`: Name of the table on the storage account to store poison messages if they cannot be processed.
- `BackgroundProcessorMaxRetryCount`: How often the BackgroundProcessor should retry to process a message if it fails, for example because Cosmos DB is not available.
- `BackgroundProcessorRetryWaitSeconds`: How many seconds to wait between each retry attempt. Wait time is `RetryAttempt * BackgroundProcessorRetryWaitSeconds`

## Logging and tracing

The BackgroundProcessor uses the `Microsoft.ApplicationInsights.WorkerService` NuGet package to get out-of-the-box instrumentation from the application. Also, [Serilog](https://github.com/serilog/serilog-extensions-logging) is used for all logging inside the application with Azure Application Insights configured as a sink (next to the Console sink). Only when needed to track additional metrics, a `TelemetryClient` instance for ApplicationInsights is used directly.

## Partition ownership and checkpointing

The Azure EventHub Processor library uses (by default) Azure Blob Storage to manage partition ownership, load balance between different worker instances and to track progress using checkpoints. The details on this can be found in the [official documentation](https://learn.microsoft.com/azure/event-hubs/event-processor-balance-partition-load#partition-ownership-tracking).

Writing the checkpoints to the blob storage does not happen after every event as this would add a prohibitively expensive delay for every message. Instead the checkpoint writing happens on a timer-loop (configurable duration with a current setting of 10 seconds):

```csharp
while (!stoppingToken.IsCancellationRequested)
    {
        await Task.Delay(TimeSpan.FromSeconds(_sysConfig.BackendCheckpointLoopSeconds), stoppingToken);
        if (!stoppingToken.IsCancellationRequested && !checkpointEvents.IsEmpty)
        {
            string lastPartition = null;
            try
            {
                foreach (var partition in checkpointEvents.Keys)
                {
                    lastPartition = partition;
                    if (checkpointEvents.TryRemove(partition, out ProcessEventArgs lastProcessEventArgs))
                    {
                        if (!lastProcessEventArgs.HasEvent)
                        {
                            _logger.LogWarning("lastProcessEventArgs for partiton={partition} has no event. Nothing to be checkpointed", partition);
                        }
                        else
                        {
                            _logger.LogDebug("Scheduled checkpointing for partition {partition}. Offset={offset}", partition, lastProcessEventArgs.Data.Offset);
                            await lastProcessEventArgs.UpdateCheckpointAsync();
                        }
                    }
                }
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception during checkpointing loop for partition={lastPartition}", lastPartition);
            }
        }
    }
```

## Event Processing, retries and poison message storage

As an `EventProcessorClient` the BackgroundProcessor can listen to one or more partitions of the Event Hub (managed by the aforementioned mechanism for partition ownership). Within each partition, events are received sequentially and need to be processed one by one. This is implemented in the `ProcessEventHandlerAsync(ProcessEventArgs eventArgs)` function. This function must only return once the processing of an event is fully completed. That means either:

- The event was successfully processed. Usually this means some write operation to the database was executed.
- The event was discarded because it is a health check message (see below).
- The event could not be processed and therefore was written to the poison message store for manual inspection.

Once processing has finished in one of these ways, the checkpoint mark for this partition is moved forward so that this event will not be processed again (after the checkpoint has been written to the storage account as explained above).

If there is an error during processing which can be retried, for instance if the database is not available at the moment, the processor waits and retries the event again. If the error is not retrieable or the maximum number of retries was reached, it gives up and writes the event to the poison store instead:

```csharp
catch (AlwaysOnDependencyException e)
{
    int retries = 1;
    retryCounters.TryGetValue(eventArgs.Partition.PartitionId, out retries);

    if(retries > _sysConfig.BackgroundProcessorMaxRetryCount)
    {
        _logger.LogError("Retried event messageId={messageId} already {retries}/{maxRetries} times. Giving up, writing Event to poision queue.", eventArgs.Data.MessageId, retries, _sysConfig.BackgroundProcessorMaxRetryCount);
        await WriteErroredEventToPoisonMessageStoreAsync(eventArgs);
    }
    else
    {
        var retryDelay = TimeSpan.FromSeconds(retries * _sysConfig.BackgroundProcessorRetryWaitSeconds); // Exponential backoff
        _logger.LogError("AlwaysOnDependencyException occured while processing event messageId={messageId}, StatusCode={statusCode}. Will retry after {retryDelay}. Retry attempt: {retry}/{maxRetries}", eventArgs.Data.MessageId, e.StatusCode, retryDelay, retries, _sysConfig.BackgroundProcessorMaxRetryCount);
        retries++;
        retryCounters.AddOrUpdate(eventArgs.Partition.PartitionId, retries, (key, existingValue) => { return retries; }); // Update retry counter for this partition
        await Task.Delay(retryDelay);
        // Try processing again

        await ProcessEventHandlerAsync(eventArgs);
    }
}
catch (Exception e)
{
    _logger.LogError(e, "An unexpected exception occured while processing event messageId={messageId}. Cannot process, writing event to poision queue.", eventArgs.Data.MessageId);
    await WriteErroredEventToPoisonMessageStoreAsync(eventArgs);
}
```

As a poison message store (sometimes also generically referred to as "Poison Queue"), AlwaysOn uses a Table on a Storage Account. From there messages can easily be manually inspected later.

```csharp
private async Task WriteErroredEventToPoisonMessageStoreAsync(ProcessEventArgs eventArgs)
{

    var entity = new TableEntity(eventArgs.Partition.PartitionId, eventArgs.Data.MessageId);
    var eventBody = Encoding.UTF8.GetString(eventArgs.Data.Body.Span);
    entity.Add("EventBody", eventBody);

    // ...

    entity.TryAdd("EnqueuedTime", eventArgs.Data.EnqueuedTime);
    await _tableClient.AddEntityAsync(entity);
}
```

## Healthcheck messages

Event Hub's health is verified by sending a message with a specific property (see [HealthService Readme](/src/app/AlwaysOn.HealthService/README.md)):

```bash
HEALTHCHECK=TRUE
```

And because the worker service has to react to it, it basically inspects properties of every incoming message and if `HEALTHCHECK` is found and the value is `TRUE`, it simply stops processing this message.

```csharp
// Discard healthcheck messages
if (eventData.Properties.TryGetValue("HEALTHCHECK", out object value) && (string)value == "TRUE")
{
    _logger.LogDebug("Received a healthcheck message. Discarding message");
    return;
}
```

Currently, there is no correlation between sending and receiving of Event Hub messages, so the validation only checks if the application is able to post messages to EH, but not end-to-end processing.

## Kubernetes Liveness health probe

Since the BackgroundProcessor does not expose a HTTP interface, it needs a different mechanism for Kubernetes to probe for the pod's liveness. For this, it uses a [custom Health Check implementation](/src/app/AlwaysOn.BackgroundProcessor/HealthCheckPublisher.cs) which writes a temporary file to the container filesystem and deletes it if the application needs to report "unhealthy". Kubernetes then uses the `exec` mode of the livenessProbe to validate if the file is present and was recently modified (see [deployment.yaml](/src/app/charts/backgroundprocessor/templates/deployment.yaml)).

The health check currently does not implement any special logic, for now it mostly serves as an example how to implement such probes on headless (no HTTP interface) services.

---

[Back to documentation root](/docs/README.md)
