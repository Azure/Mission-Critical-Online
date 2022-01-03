using AlwaysOn.Shared;
using AlwaysOn.Shared.Exceptions;
using Azure.Data.Tables;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.BackgroundProcessor.Services
{
    /// <summary>
    /// This service connects to an EventHub and processes messages from it
    /// Sends received and decoded messages off to the ActionProcessorService for actual processing towards the database
    /// </summary>
    public class EventHubProcessorService : BackgroundService
    {
        private readonly ILogger<EventHubProcessorService> _logger;
        private readonly SysConfiguration _sysConfig;
        private readonly BlobContainerClient _blobContainerClient;
        private readonly TableClient _tableClient;
        private readonly EventProcessorClient _processor;
        private readonly ActionProcessorService _actionProcessorService;
        private readonly TelemetryClient _telemetryClient;

        /// <summary>
        /// Dictionary of checkpoint events per partition. Key=partitionId
        /// Needs to be ThreadSafe since multiple threads could be running on this processor, one for each owned partition
        /// </summary>
        private readonly ConcurrentDictionary<string, ProcessEventArgs> checkpointEvents = new();

        /// <summary>
        /// Dictionary of retry counter per partition. Key=partitionId
        /// Needs to be ThreadSafe since multiple threads could be running on this processor, one for each owned partition
        /// </summary>
        private readonly ConcurrentDictionary<string, int> retryCounters = new();

        /// <summary>
        /// List of partitionIds which are owned by this processor instance
        /// Needs to be ThreadSafe since multiple threads could be running on this processor, one for each owned partition
        /// </summary>
        private readonly ConcurrentDictionary<string, DateTime> ownedPartitions = new();

        public EventHubProcessorService(ILogger<EventHubProcessorService> logger, SysConfiguration sysConfig, ActionProcessorService actionProcessorService, TelemetryClient tc)
        {
            _logger = logger;
            _sysConfig = sysConfig;
            _telemetryClient = tc;
            _actionProcessorService = actionProcessorService;

            // Blob container client for checkpoint store
            _blobContainerClient = new BlobContainerClient(_sysConfig.BackendStorageConnectionString, _sysConfig.BackendCheckpointBlobContainerName);

            // Event Hub Processor client
            _processor = new EventProcessorClient(_blobContainerClient, _sysConfig.BackendReaderEventHubConsumergroup, _sysConfig.BackendReaderEventHubConnectionString, new EventProcessorClientOptions() { TrackLastEnqueuedEventProperties = true });

            // Table client for the poison message store. We expect the table itself was already created as part of the infrastructure (see Terraform IaC)
            _tableClient = new TableClient(_sysConfig.BackendStorageConnectionString, SysConfiguration.BackendStoragePoisonMessagesTableName);
        }

        /// <summary>
        /// The function is called when the BackgroundService is started
        /// </summary>
        /// <param name="stoppingToken"></param>
        /// <returns></returns>
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("EventHubProcessor starting at: {time}", DateTimeOffset.Now);

            _processor.PartitionInitializingAsync += PartitionInitializingHandler;
            _processor.PartitionClosingAsync += PartitionClosingHandler;
            _processor.ProcessEventAsync += ProcessEventHandlerAsync;
            _processor.ProcessErrorAsync += ProcessErrorHandler;

            // Start listening for new events
            await _processor.StartProcessingAsync(stoppingToken);

            // This is the checkpointing loop
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(_sysConfig.BackendCheckpointLoopSeconds), stoppingToken);
                if (!stoppingToken.IsCancellationRequested && !checkpointEvents.IsEmpty)
                {
                    string lastPartition = null;
                    try
                    {
                        _logger.LogInformation($"Checkpointing loop executed for {ownedPartitions.Count} owned partitions ({string.Join(',', ownedPartitions)})");
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
                                    _logger.LogInformation("Scheduled checkpointing for partition {partition}. Offset={offset}", partition, lastProcessEventArgs.Data.Offset);
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
            _logger.LogInformation("ExecuteAsync ending");
        }

        /// <summary>
        /// Event Handler that is called for every received message
        /// </summary>
        private async Task ProcessEventHandlerAsync(ProcessEventArgs eventArgs)
        {
            try
            {
                var eventData = eventArgs.Data;

                _logger.LogInformation("Event messageId={messageId} received from partition {partitionId}", eventArgs.Data.MessageId, eventArgs.Partition.PartitionId);

                // Track lag metric
                // This metric shows how far behind the head of the queue the processor is
                var lastEnqueuedEvent = eventArgs.Partition.ReadLastEnqueuedEventProperties();
                var lag = lastEnqueuedEvent.SequenceNumber - eventData.SequenceNumber;
                var metric = new MetricTelemetry("EventHubLag", (double)lag);
                metric.Properties.Add("partitionId", eventArgs.Partition.PartitionId);
                _telemetryClient.TrackMetric(metric);

                // Filter out and discard healthcheck messages
                if (eventData.Properties.TryGetValue("HEALTHCHECK", out object value) && (string)value == "TRUE")
                {
                    _logger.LogDebug("Received a healthcheck message. Discarding message");
                    return;
                }

                if (!eventData.Properties.TryGetValue("action", out object actionProperty))
                {
                    _logger.LogWarning("Message did not contain an 'action' property. Discarding message");
                    return;
                }
                string action = (string)actionProperty;

                var messageBody = Encoding.UTF8.GetString(eventData.Body.Span);

                _logger.LogInformation("Starting to process action {action}, partitionId={partitionId}", action, eventArgs.Partition.PartitionId);
                // Hand over to the action processor service. This will handle database writes etc
                await _actionProcessorService.Process(action, messageBody);

                // reset retry counter by removing it, if it existed
                if (retryCounters.TryRemove(eventArgs.Partition.PartitionId, out int retries))
                {
                    _logger.LogInformation("Reset retry counter on partition {partitionId}. Last value: {retries}", eventArgs.Partition.PartitionId, retries);
                }

                _logger.LogInformation("Event messageId={messageId} processing completed", eventArgs.Data.MessageId);
            }
            catch (AlwaysOnDependencyException e)
            {           
                int retries = 1;
                retryCounters.TryGetValue(eventArgs.Partition.PartitionId, out retries);

                if(retries > _sysConfig.BackgroundProcessorMaxRetryCount)
                {
                    _logger.LogError("Retried event messageId={messageId} already {retries}/{maxRetries} times. Giving up, writing Event to poison queue.", eventArgs.Data.MessageId, retries, _sysConfig.BackgroundProcessorMaxRetryCount);
                    await WriteErroredEventToPoisonMessageStoreAsync(eventArgs);
                }
                else
                {
                    var retryDelay = TimeSpan.FromSeconds(retries * _sysConfig.BackgroundProcessorRetryWaitSeconds); // Linear backoff
                    _logger.LogError("AlwaysOnDependencyException occured while processing event messageId={messageId}, StatusCode={statusCode}. Will retry after {retryDelay}. Retry attempt: {retry}/{maxRetries}", eventArgs.Data.MessageId, e.StatusCode, retryDelay, retries, _sysConfig.BackgroundProcessorMaxRetryCount);
                    retries++;
                    retryCounters.AddOrUpdate(eventArgs.Partition.PartitionId, retries, (key, existingValue) => { return retries; }); // Update retry counter for this partition
                    await Task.Delay(retryDelay);
                    // Try processing again
                    _logger.LogInformation("Retrying event processing now for messageId={messageId}", eventArgs.Data.MessageId);
                    await ProcessEventHandlerAsync(eventArgs);
                }
            }
            catch (Exception e)
            {
                _logger.LogError(e, "An unexpected exception occured while processing event messageId={messageId}. Cannot process, writing event to poison queue.", eventArgs.Data.MessageId);
                await WriteErroredEventToPoisonMessageStoreAsync(eventArgs);
            }
            finally
            {
                // Now we can checkpoint this event. We dont need to process it again
                checkpointEvents.AddOrUpdate(eventArgs.Partition.PartitionId, eventArgs, (key, existingValue) => { return eventArgs; });
            }
        }

        /// <summary>
        /// Writes an event that cannot be processed to a poison message store.
        /// In our case that is a Table storage
        /// Tries to parse the message body as UTF-8 and also stores all message properties
        /// </summary>
        /// <param name="eventArgs"></param>
        /// <returns></returns>
        private async Task WriteErroredEventToPoisonMessageStoreAsync(ProcessEventArgs eventArgs)
        {
            try
            {
                var entity = new TableEntity(eventArgs.Partition.PartitionId, eventArgs.Data.MessageId);
                var eventBody = Encoding.UTF8.GetString(eventArgs.Data.Body.Span);
                entity.Add("EventBody", eventBody);

                var cleanerRegex = new Regex(@"[-,;\./_\\\s]");
                // add all properties
                foreach (var property in eventArgs.Data.Properties)
                {                 
                    var cleanedKey = cleanerRegex.Replace(property.Key, ""); // Remove special chars from key name else Table will complain
                    _logger.LogDebug("Adding event property key={key}, value={value} to TableEntity", cleanedKey, property.Value.ToString());
                    entity.TryAdd(cleanedKey, property.Value?.ToString());
                }

                entity.TryAdd("EventHubPartitionId", eventArgs.Partition.PartitionId);
                entity.TryAdd("EventHubEnqueuedTime", eventArgs.Data.EnqueuedTime);
                entity.TryAdd("EventHubSequenceNumber", eventArgs.Data.SequenceNumber);
                entity.TryAdd("EventHubOffset", eventArgs.Data.Offset);

                _logger.LogInformation("Writing event messageId={messageId} to poison message table store", eventArgs.Data.MessageId);
                await _tableClient.AddEntityAsync(entity);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception during writing to the poison message table store, messageId={messageId}. Data might have been lost!", eventArgs.Data.MessageId);
            }
        }

        private Task ProcessErrorHandler(ProcessErrorEventArgs eventArgs)
        {
            var msg = $"The error handler was invoked during the operation: { eventArgs.Operation ?? "Unknown" }, for Exception: { eventArgs.Exception?.Message }";
            _logger.LogError(eventArgs.Exception, msg);
            return Task.CompletedTask;
        }

        private Task PartitionInitializingHandler(PartitionInitializingEventArgs eventArgs)
        {
            try
            {
                ownedPartitions.TryAdd(eventArgs.PartitionId, DateTime.UtcNow);
                _logger.LogInformation("Initialized partition: {partitionId}", eventArgs.PartitionId);
                _logger.LogInformation("Now owning {numberOfOwnedPartitions} partition(s)", ownedPartitions.Count);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "An error was observed while initializing partition: {partitionId}", eventArgs.PartitionId);
            }

            return Task.CompletedTask;
        }

        private async Task PartitionClosingHandler(PartitionClosingEventArgs eventArgs)
        {
            try
            {
                _logger.LogInformation("Closing partition={partitionId} because of {partitionClosingReason}", eventArgs.PartitionId, eventArgs.Reason);

                if (checkpointEvents.TryRemove(eventArgs.PartitionId, out ProcessEventArgs lastProcessEventArgs))
                {
                    if (lastProcessEventArgs.HasEvent)
                    {
                        _logger.LogInformation("Checkpointing for partition {partitionId} on partition closing", eventArgs.PartitionId);
                        await lastProcessEventArgs.UpdateCheckpointAsync();
                    }
                }
                ownedPartitions.TryRemove(eventArgs.PartitionId, out DateTime ownershipStartTime);
                _logger.LogInformation("Now owning {numberOfOwnedPartitions} partition(s)", ownedPartitions.Count);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "An error was observed while closing partition: {partitionId}", eventArgs.PartitionId);
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation($"{nameof(StopAsync)} started. Stopping EventHubProcessor");
            try
            {
                if (_processor != null)
                {
                    await _processor.StopProcessingAsync();
                    // Give enough time to close all partitions
                    await Task.Delay(3000);
                }
            }
            finally
            {
                _processor.PartitionInitializingAsync -= PartitionInitializingHandler;
                _processor.PartitionClosingAsync -= PartitionClosingHandler;
                _processor.ProcessEventAsync -= ProcessEventHandlerAsync;
                _processor.ProcessErrorAsync -= ProcessErrorHandler;
            }
            await base.StopAsync(cancellationToken);
        }
    }
}
