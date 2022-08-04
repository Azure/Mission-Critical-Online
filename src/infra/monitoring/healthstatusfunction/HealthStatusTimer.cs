using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace HealthStatusFunction
{
    public class HealthStatusTimer
    {
        [FunctionName("HealthStatusTimer")]
        public async Task Run(  
                [TimerTrigger("%TimerSchedule%")]TimerInfo myTimer, // 0 */5 * * * *
                ILogger log
                )
        {
            // NOTE ON LOG ANALYTICS AUTHENTICATION:
            // Log Analytics query APIs use Azure AD authentication. We're using the Azure managed identity for that.
            // The Log Analytics Data Collector API does not support that and only accepts a shared key.
            // For this reason, the function requires BOTH managed identity to be enabled as well as having the shared key in the app settings. 
            
            string workspaceId = Environment.GetEnvironmentVariable("LA_WORKSPACE_ID").ToString();
            string workspaceKey = Environment.GetEnvironmentVariable("LA_WORKSPACE_KEY").ToString();

            // We want to align the query timespan to the Function's schedule. We're storing that as an env variable, so we can retrieve it.
            string schedule = Environment.GetEnvironmentVariable("TimerSchedule").ToString();

            try {
                await new HealthStatusFunction(log, workspaceId, workspaceKey, GetCronMinutes(schedule)).PostHealthData();
            }
            catch(Exception ex) {
                log.LogError(ex, "Error in HealthStatusTimer");
            }
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
        }
        
        private static int GetCronMinutes(string expression)
        {
            string mins = expression.Split(' ')[1];
            return int.Parse(mins[(mins.IndexOf('/')+1)..]);
        }
    }
}
