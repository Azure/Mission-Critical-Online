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

        private readonly List<IAlwaysOnHealthCheck> _healthChecks;

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

            _healthChecks = new List<IAlwaysOnHealthCheck>();

            // Check database querying?
            if (_sysConfig.HealthServiceDatabaseHealthCheckEnabled)
            {
                _healthChecks.Add(_databaseService);
            }

            // Check state blob?
            if (_sysConfig.HealthServiceBlobStorageHealthCheckEnabled)
            {
                _healthChecks.Add(_blobStorageHealthCheck);
            }

            // Check message sending?
            if (_sysConfig.HealthServiceMessageProducerHealthCheckEnabled)
            {
                _healthChecks.Add(_messageProducerService);
            }

            // Check Az Monitor for stamp HealthScore?
            if (_sysConfig.HealthServiceAzMonitorHealthScoreHealthCheckEnabled)
            {
                _healthChecks.Add(_azMonitorHealthScoreCheck);
            }
        }

        /// <summary>
        /// Checks downstream dependencies like Message Producer and database service for their health
        /// Uses caching in order not to overload the components just with health checks
        /// </summary>
        /// <param name="context"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default(CancellationToken))
        {

            // Create healthCheck tasks for all of them
            var checkTasks = _healthChecks.Select(c => CreateHealthCheckTask(c, cancellationToken)).ToDictionary(c => c.Name, c => c.CheckTask);

            // Run all checks in parallel
            await Task.WhenAll(checkTasks.Values);

            var properties = checkTasks.ToDictionary(c => c.Key, c => (object)c.Value.Result);

            // If any one of the checks is false (= unhealthy), report overall unhealthy
            if (checkTasks.Any(t => t.Value.Result == false))
            {
                return HealthCheckResult.Unhealthy(data: properties);
            }

            return HealthCheckResult.Healthy(data: properties);
        }

        private (string Name, Task<bool> CheckTask) CreateHealthCheckTask(IAlwaysOnHealthCheck healthCheck, CancellationToken cancellationToken)
        {
            var task = _cache.GetOrCreateAsync(healthCheck.HealthCheckComponentName, entry =>
            {
                var result = healthCheck.IsHealthy(cancellationToken);
                _log.LogDebug("Probing {healthCheck} - Cache empty or expired", healthCheck.HealthCheckComponentName);
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
                return result;
            });
            return (Name: healthCheck.HealthCheckComponentName, CheckTask: task);
        }
    }
}
