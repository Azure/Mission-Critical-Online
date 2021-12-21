using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace AlwaysOn.SloProcessor
{
    public static class SloProcessTimerTrigger
    {
        // Update workspaceId to your Log Analytics workspace ID
        private static string[] stampWorkspaceIds = Environment.GetEnvironmentVariable("LA_WORKSPACE_IDS_STAMPS").ToString().Split('|');
        private static string globalWorkspaceId = Environment.GetEnvironmentVariable("LA_WORKSPACE_ID_GLOBAL");
        // For sharedKey, use either the primary or the secondary Connected Sources client authentication key   
        private static string globalSharedKey = Environment.GetEnvironmentVariable("LA_WORKSPACE_SHARED_KEY_GLOBAL");

        [FunctionName(nameof(SloProcessTimerTrigger))]
        public static async Task Run([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer, // run every 5min
            ILogger log)
        {
            log.LogInformation($"SLO Query Timer trigger function executed at: {DateTime.Now}");
            if (stampWorkspaceIds.Length > 0)
            {
                SloProcessor sloproc = new SloProcessor(log);
                foreach (string laWorkspaceId in stampWorkspaceIds)
                {
                    var json = await sloproc.GetSloData(laWorkspaceId);
                    await sloproc.StoreQueryResult(globalWorkspaceId, globalSharedKey, json);
                }
            }
            else
            {
                log.LogError("There are not workspaces configured in env var LA_WORKSPACE_IDS_STAMPS");
            }

            log.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus.Next}");
        }
    }
}