using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public static class LoadSettingFunctionTimer
    {
        [Function(nameof(LoadSettingFunctionTimer))]
        public static async Task Run([TimerTrigger("0 */10 * * * *")] TimerInfo myTimer, // run every 10min
            ILogger log)
        {
            log.LogInformation($"{nameof(LoadSettingFunctionTimer)} executed at: {DateTime.Now}");
            await LoadSetter.LoadSetterInternalAsync(log);
        }
    }
}