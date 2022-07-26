using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace HealthStatusFunction
{
    public class HealthStatusTimer
    {
        [FunctionName("HealthStatusTimer")]
        public async Task Run(  
                //[HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
                [TimerTrigger("0 */5 * * * *")]TimerInfo myTimer, 
                ILogger log
                )
        {
            // NOTE ON LOG ANALYTICS AUTHENTICATION:
            // Log Analytics query APIs use Azure AD authentication. We're using the Azure managed identity for that.
            // The Log Analytics Data Collector API does not support that and only accepts a shared key.
            // For this reason, the function requires BOTH managed identity to be enabled as well as having the shared key in the app settings. 
            
            string workspaceId = Environment.GetEnvironmentVariable("LA_WORKSPACE_ID").ToString();
            string workspaceKey = Environment.GetEnvironmentVariable("LA_WORKSPACE_KEY").ToString();

            try {
                await new HealthStatusFunction(log, workspaceId, workspaceKey).PostHealthData();
            }
            catch(Exception ex) {
                log.LogError(ex, "Error in HealthStatusTimer");
            }
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
        }
    }
}
