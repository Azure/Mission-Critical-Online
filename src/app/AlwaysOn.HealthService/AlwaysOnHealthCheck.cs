using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Net.Http;
using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;

namespace AlwaysOn.HealthService
{
    public class AlwaysOnHealthCheck : IHealthCheck
    {
        private const string STATE_BLOB_CACHE_KEY = "stateBlobHealth";
        private const string STATE_MESSAGE_PRODUCER_CACHE_KEY = "stateMessageProducerHealth";
        private const string STATE_DATABASE_CACHE_KEY = "stateDatabaseHealth";
        private const string STATE_LIVENESS_ENDPOINT_1_CACHE_KEY = "stateLivenessEndpointHealth";

        private readonly ILogger<AlwaysOnHealthCheck> _log;
        private readonly SysConfiguration _sysConfig;
        private readonly IDatabaseService _databaseService;

        private readonly IMessageProducerService _messageProducerService;
        private IMemoryCache _cache;

        public AlwaysOnHealthCheck(ILogger<AlwaysOnHealthCheck> log,
            SysConfiguration sysConfig,
            IMemoryCache memoryCache,
            IDatabaseService databaseService,
            IMessageProducerService messageProducerService)
        {
            _log = log;
            _sysConfig = sysConfig;
            _cache = memoryCache;
            _databaseService = databaseService;
            _messageProducerService = messageProducerService;
        }

        /// <summary>
        /// Checks downstream dependencies like Message Producer and database service for their health
        /// Also, checks the state blob storage
        /// Uses caching in order not to overload the components just with health checks
        /// </summary>
        /// <param name="context"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            // Check state blob
            var stateBlobIsHealthyTask = _cache.GetOrCreateAsync(STATE_BLOB_CACHE_KEY, entry =>
            {
                var result = GetStateBlobHealth(cancellationToken);
                _log.LogDebug("Probing state blob health state - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            // Check message sending
            var messageProducerIsHealthyTask = _cache.GetOrCreateAsync(STATE_MESSAGE_PRODUCER_CACHE_KEY, entry =>
            {
                var result = _messageProducerService.IsHealthy(cancellationToken);
                _log.LogDebug("Probing message producer health state - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            // Check (additional) liveness endpoint 1 health state
            var livenessEndpoint1Healthy = _cache.GetOrCreateAsync(STATE_LIVENESS_ENDPOINT_1_CACHE_KEY, entry =>
            {
                var result = GetLivenessEndpoint1Status(cancellationToken);
                _log.LogDebug("Probing liveness endpoint 1 health state - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            // Check database querying
            var databaseIsHealthyTask = _cache.GetOrCreateAsync(STATE_DATABASE_CACHE_KEY, entry =>
            {
                var result = _databaseService.IsHealthy(cancellationToken);
                _log.LogDebug("Probing database health state - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            // Run all checks in parallel
            await Task.WhenAll(stateBlobIsHealthyTask, messageProducerIsHealthyTask, databaseIsHealthyTask, livenessEndpoint1Healthy);

            var props = new Dictionary<string, object>();
            props.Add("StateBlobHealthy", stateBlobIsHealthyTask.Result);
            props.Add("MessageProducerServiceHealthy", messageProducerIsHealthyTask.Result);
            props.Add("DatabaseServiceHealthy", databaseIsHealthyTask.Result);
            props.Add("LivenessEndpoint1Healthy", livenessEndpoint1Healthy.Result);

            // If any one of the three is not health, report overall unhealthy
            if (!stateBlobIsHealthyTask.Result || !messageProducerIsHealthyTask.Result || !databaseIsHealthyTask.Result || !livenessEndpoint1Healthy.Result)
            {
                return HealthCheckResult.Unhealthy(data: props);
            }

            return HealthCheckResult.Healthy(data: props);
        }

        /// <summary>
        /// Checks whether the catalogservice liveness endpoint responds with HTTP 200. HTTP 200 == Healthy
        /// </summary>
        /// <returns>True=HEALTHY, False=UNHEALTHY</returns>

        private async Task<bool> GetLivenessEndpoint1Status(CancellationToken cancellationToken = default (CancellationToken))
        {
            var result = true;

            try {
                _log.LogInformation("Initiated liveness endpoint 1 {livenessEndpoint1} probe check", _sysConfig.LivenessEndpoint1);
                var status = await GetStatusCodes(_sysConfig.LivenessEndpoint1);

                if (status==HttpStatusCode.OK) {
                    result=true;
                } else {
                    _log.LogInformation("Liveness probe for {livenessEndpoint1} responded with HTTP != 200", _sysConfig.LivenessEndpoint1);
                    result=false;
                }
            } catch (Exception e) {
                result=false;
                _log.LogError(e, "Could not check liveness endpoint 1 probe. Responding with UNHEALTHY state");
            }

            return result;

        }

        public async Task<HttpStatusCode> GetStatusCodes(string url)
        {
            var client = new HttpClient();
            var response = await client.GetAsync(url);

            return response.StatusCode;
        }

        /// <summary>
        /// Checks whether the state file on blob storage exists. File exists means: Healthy
        /// </summary>
        /// <returns>True=HEALTHY, False=UNHEALTHY</returns>
        private async Task<bool> GetStateBlobHealth(CancellationToken cancellationToken = default(CancellationToken))
        {
            try
            {
                var blobContainerClient = new BlobContainerClient(_sysConfig.HealthServiceStorageConnectionString, _sysConfig.HealthServiceBlobContainerName);
                _log.LogInformation("Initiated health state blob container client at {HealthBlobContainerUrl}", blobContainerClient.Uri.ToString());

                var stateBlobClient = blobContainerClient.GetBlobClient(_sysConfig.HealthServiceBlobName);
                return await stateBlobClient.ExistsAsync(cancellationToken);

                /*
                 * As an alternative to just checking for the file's existence, we could also examine the file's content for specfic states
                 * For example: "HEALTHY, UNHEALTHY, MAINTENANCE"
                 * 
                var download = await stateBlobClient.DownloadAsync(cancellationToken);
                StreamReader reader = new StreamReader(download.Value.Content);
                string text = reader.ReadToEnd();

                _log.LogInformation("State blob '{stateBlobName}' present. Content: {state}", _stateBlobName, text);
                return text == "HEALTHY";
                */
            }
            catch (Exception e)
            {
                // If the file does not exist or we cannot reach our storage at all, we treat this a an unhealthy state
                // as well as it might very well mean that storage in that region has an issue.
                _log.LogError(e, "Could not check health state blob. Responding with UNHEALTHY state");
                return false;
            }
        }
    }
}
