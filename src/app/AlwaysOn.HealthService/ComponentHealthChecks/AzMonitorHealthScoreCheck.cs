using AlwaysOn.Shared;
using Azure.Core;
using Azure.Monitor.Query;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService.ComponentHealthChecks
{
    public class AzMonitorHealthScoreCheck : IHealthCheck
    {
        private readonly ILogger<AzMonitorHealthScoreCheck> _logger;
        private readonly SysConfiguration _sysConfig;
        private readonly LogsQueryClient _logsQueryClient;

        public AzMonitorHealthScoreCheck(ILogger<AzMonitorHealthScoreCheck> logger,
            TokenCredential tokenCredential,
            SysConfiguration sysConfig)
        {
            _logger = logger;
            _sysConfig = sysConfig;

            _logsQueryClient = new LogsQueryClient(tokenCredential);
        }

        /// <summary>
        /// Query regional Log Analytics workspace to fetch the latest HealthStatus
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            try
            {
                var response = await _logsQueryClient.QueryWorkspaceAsync(
                    _sysConfig.RegionalLogAnalyticsWorkspaceId,
                    _sysConfig.HealthServiceAzMonitorHealthStatusQuery,
                    new QueryTimeRange(TimeSpan.FromMinutes(10)),
                    cancellationToken: cancellationToken);

                foreach (var row in response.Value.Table.Rows)
                {
                    var isHealthy = row.GetBoolean("Healthy");
                    _logger.LogDebug($"TimeGenerated: [{row["TimeGenerated"]}] Healthy: {isHealthy}");
                    if (isHealthy == null || !(bool)isHealthy)
                    {
                        _logger.LogInformation($"Health query returned unhealthy. Reporting stamp as unhealty!");
                        return new HealthCheckResult(HealthStatus.Unhealthy);
                    }
                }
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Could not query Log Analytics health status. Ensure your query returns columns 'TimeGenerated' and 'Healthy' and that the Log Analytics workspace is available. Responding with UNHEALTHY state");
                return new HealthCheckResult(HealthStatus.Unhealthy, exception: e);
            }
            return new HealthCheckResult(HealthStatus.Healthy);
        }
    }
}
