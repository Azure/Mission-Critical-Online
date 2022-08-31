using AlwaysOn.Shared;
using Azure.Identity;
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
            SysConfiguration sysConfig)
        {
            _logger = logger;
            _sysConfig = sysConfig;

            _logsQueryClient = new LogsQueryClient(new DefaultAzureCredential(new DefaultAzureCredentialOptions()
            {
                ManagedIdentityClientId = _sysConfig.ManagedIdentityClientId
            }));
        }

        /// <summary>
        /// Query regional Log Analytics workspace to fetch the latest HealthScore
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            try
            {
                var response = await _logsQueryClient.QueryWorkspaceAsync(
                    _sysConfig.RegionalLogAnalyticsWorkspaceId,
                    _sysConfig.HealthServiceAzMonitorHealthScoreQuery,
                    new QueryTimeRange(TimeSpan.FromMinutes(10)),
                    cancellationToken: cancellationToken);

                var table = response.Value.Table;

                foreach (var row in table.Rows) // there will be only one row (take 1)
                {
                    var healthScore = row.GetDouble("HealthScore");
                    _logger.LogDebug($"TimeGenerated: [{row["TimeGenerated"]}] HealthScore: {healthScore}");
                    // If the healthscore indicates red, return false
                    if (healthScore <= _sysConfig.HealthServiceAzMonitorHealthScoreThreshold)
                    {
                        _logger.LogInformation($"HealthScore of {healthScore} is <= {_sysConfig.HealthServiceAzMonitorHealthScoreThreshold}. Reporting stamp as unhealty!");
                        return new HealthCheckResult(HealthStatus.Unhealthy);
                    }
                }
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Could not query Log Analytics health score. Responding with UNHEALTHY state");
                return new HealthCheckResult(HealthStatus.Unhealthy, exception: e);
            }
            return new HealthCheckResult(HealthStatus.Healthy);
        }
    }
}
