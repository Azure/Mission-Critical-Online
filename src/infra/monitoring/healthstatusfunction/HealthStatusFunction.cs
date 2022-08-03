using System;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace HealthStatusFunction
{
    class HealthStatusFunction
    {
        private const string healthStatusTableName = "ComponentHealthStatus";
        private readonly ILogger _logger;
        private LogAnalyticsConnector logAnalytics;
        private readonly string workspaceId;
        private readonly int interval;

        public HealthStatusFunction(ILogger logger, string workspaceId, string sharedKey, int interval)
        {
            _logger = logger;
            this.logAnalytics = new LogAnalyticsConnector(workspaceId, sharedKey, logger);
            this.workspaceId = workspaceId;
            this.interval = interval;
        }

        public async Task PostHealthData() 
        {
            // Get the health status data from LA. This is what we're going to post back to the HealthStatus table
            string logQuery = "AllHealthStatus()";
            string healthData = await logAnalytics.GetLogData(logQuery, TimeSpan.FromMinutes(interval));
            bool result = await logAnalytics.PostData(healthStatusTableName, healthData);

            if(result)
            {
                _logger.LogInformation("Health status data posted to Log Analytics");
            }
            else
            {
                _logger.LogError("Error posting health status data to Log Analytics");
            }    
        }
    }
}