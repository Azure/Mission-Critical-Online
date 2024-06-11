using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public static class LoadSettingFunctionTimer
    {
        [FunctionName(nameof(LoadSettingFunctionTimer))]
        public static async Task Run([TimerTrigger("0 */10 * * * *")] TimerInfo myTimer, // run every 10min
            ExecutionContext context,
            ILogger log)
        {
            log.LogInformation($"{nameof(LoadSettingFunctionTimer)} executed at: {DateTime.Now}");
            await LoadSetter.LoadSetterInternalAsync(context, log);
        }
    }
}
