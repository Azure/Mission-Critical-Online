using AlwaysOn.HealthService.ComponentHealthChecks;
using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService
{
    public class AlwaysOnHealthCheck : IHealthCheck
    {
        private const string STATE_BLOB_CACHE_KEY = "stateBlobHealth";
        private const string STATE_MESSAGE_PRODUCER_CACHE_KEY = "stateMessageProducerHealth";
        private const string STATE_DATABASE_CACHE_KEY = "stateDatabaseHealth";
        private const string STATE_AZMONITOR_CACHE_KEY = "stateAzMonitorHealth";

        private readonly ILogger<AlwaysOnHealthCheck> _log;
        private readonly SysConfiguration _sysConfig;
        private readonly IDatabaseService _databaseService;
        private readonly IMessageProducerService _messageProducerService;
        private readonly AzMonitorHealthScoreCheck _azMonitorHealthScoreCheck;
        private readonly BlobStorageHealthCheck _blobStorageHealthCheck;
        private IMemoryCache _cache;

        public AlwaysOnHealthCheck(ILogger<AlwaysOnHealthCheck> log,
            SysConfiguration sysConfig,
            IMemoryCache memoryCache,
            IDatabaseService databaseService,
            IMessageProducerService messageProducerService,
            AzMonitorHealthScoreCheck azMonitorHealthScoreCheck,
            BlobStorageHealthCheck blobStorageHealthCheck)
        {
            _log = log;
            _sysConfig = sysConfig;
            _cache = memoryCache;
            _databaseService = databaseService;
            _messageProducerService = messageProducerService;
            _azMonitorHealthScoreCheck = azMonitorHealthScoreCheck;
            _blobStorageHealthCheck = blobStorageHealthCheck;
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
                var result = _blobStorageHealthCheck.GetStateBlobHealth(cancellationToken);
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

            // Check database querying
            var databaseIsHealthyTask = _cache.GetOrCreateAsync(STATE_DATABASE_CACHE_KEY, entry =>
            {
                var result = _databaseService.IsHealthy(cancellationToken);
                _log.LogDebug("Probing database health state - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            // Check Az Monitor for stamp HealthScore
            var azMonitorIsHealthyTask = _cache.GetOrCreateAsync(STATE_AZMONITOR_CACHE_KEY, entry =>
            {
                var result = _azMonitorHealthScoreCheck.GetStampHealthFromAzMonitor(cancellationToken);
                _log.LogDebug("Probing Azure Monitor for stamp HealthScore - Cache empty or expired");
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });

            var checkTasks = new[] { stateBlobIsHealthyTask, messageProducerIsHealthyTask, databaseIsHealthyTask, azMonitorIsHealthyTask };

            // Run all checks in parallel
            await Task.WhenAll(checkTasks);

            var props = new Dictionary<string, object>
            {
                { "StateBlobHealthy", stateBlobIsHealthyTask.Result },
                { "MessageProducerServiceHealthy", messageProducerIsHealthyTask.Result },
                { "DatabaseServiceHealthy", databaseIsHealthyTask.Result },
                { "StampHealthScoreOk", azMonitorIsHealthyTask.Result }
            };

            // If any one of the checks is false (= unhealthy), report overall unhealthy
            if (checkTasks.Any(t => t.Result == false))
            {
                return HealthCheckResult.Unhealthy(data: props);
            }

            return HealthCheckResult.Healthy(data: props);
        }
    }
}
