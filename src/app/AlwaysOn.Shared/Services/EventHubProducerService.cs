using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Services
{
    public class EventHubProducerService : IMessageProducerService, IDisposable
    {
        private readonly ILogger<EventHubProducerService> _logger;
        private readonly EventHubProducerClient _eventHubProducerClient;

        // Expects to find FrontendSenderEventHubConnectionString in SysConfiguration.
        public EventHubProducerService(ILogger<EventHubProducerService> logger, SysConfiguration sysConfig)
        {
            _logger = logger;
            _eventHubProducerClient = new EventHubProducerClient(sysConfig.FrontendSenderEventHubConnectionString);

            _logger.LogInformation("Initializing Event Hub producer client with Event Hub namespace {eventHubNamespace}", _eventHubProducerClient.FullyQualifiedNamespace);
        }

        /// <summary>
        /// Very simple health check. Attempts to send an empty message
        /// Adds a property "HEALTHCHECK=TRUE" to the message
        /// </summary>
        /// <returns></returns>
        public async Task<bool> IsHealthy(CancellationToken cancellationToken = default(CancellationToken))
        {
            _logger.LogDebug("Event Hub health probe requested");
            if (_eventHubProducerClient.IsClosed)
            {
                _logger.LogError($"Unexpected 'Closed' status of Event Hub in {nameof(IsHealthy)}");
                return false;
            }

            try
            {
                var message = new EventData("{}");
                message.Properties.Add("HEALTHCHECK", "TRUE");
                message.MessageId = Guid.NewGuid().ToString();
                await SendSingleEventAsync(message, cancellationToken);
                return true;
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on sending health probe message to Event Hub");
                return false;
            }
        }

        private async Task SendSingleEventAsync(EventData message, CancellationToken cancellationToken = default(CancellationToken))
        {
            await SendEventBatchAsync(new EventData[] { message }, cancellationToken);
        }

        private async Task SendEventBatchAsync(IEnumerable<EventData> messages, CancellationToken cancellationToken = default(CancellationToken))
        {
            try
            {
                using EventDataBatch eventBatch = await _eventHubProducerClient.CreateBatchAsync(cancellationToken);
                foreach (var e in messages)
                {
                    eventBatch.TryAdd(e);
                }
                await _eventHubProducerClient.SendAsync(eventBatch, cancellationToken);
            }
            catch (EventHubsException e)
            {
                _logger.LogError(e, "Exception on sending message to Event Hub");
                // We treat EventHubsException.FailureReason.ServiceBusy like a HTTP 429, everything else as a generic error
                var statusCode = e.Reason == EventHubsException.FailureReason.ServiceBusy ? HttpStatusCode.TooManyRequests : HttpStatusCode.InternalServerError;
                throw new AlwaysOnDependencyException(statusCode, innerException: e);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on sending message to Event Hub");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, innerException: e);
            }
        }

        public void Dispose()
        {
            _eventHubProducerClient?.DisposeAsync().GetAwaiter().GetResult();
        }

        public Task SendSingleMessageAsync(string messageBody, string action = null, CancellationToken cancellationToken = default(CancellationToken))
        {
            var data = new EventData(messageBody);
            if (!string.IsNullOrEmpty(action))
            {
                data.Properties.Add("action", action);
            }
            data.MessageId = Guid.NewGuid().ToString();
            return SendSingleEventAsync(data, cancellationToken);
        }

        public Task SendMessageBatchAsync(IEnumerable<(string messageBody, string action)> messages, CancellationToken cancellationToken = default(CancellationToken))
        {
            var batch = new List<EventData>();
            foreach (var message in messages)
            {
                if (string.IsNullOrEmpty(message.messageBody))
                {
                    continue; // Skip empty messages
                }
                var data = new EventData(message.messageBody);
                if (!string.IsNullOrEmpty(message.action))
                {
                    data.Properties.Add("action", message.action);
                }
                data.MessageId = Guid.NewGuid().ToString();
                batch.Add(data);
            }
            return SendEventBatchAsync(batch, cancellationToken);
        }
    }
}
