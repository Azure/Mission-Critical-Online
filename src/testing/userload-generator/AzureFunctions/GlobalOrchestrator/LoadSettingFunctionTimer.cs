using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public class LoadSettingFunctionTimer(ILogger<LoadSettingFunctionTimer> logger)
    {
        [Function(nameof(LoadSettingFunctionTimer))]
        public async Task Run([TimerTrigger("0 */10 * * * *")] TimerInfo myTimer) // run every 10min
        {
            logger.LogInformation($"{nameof(LoadSettingFunctionTimer)} executed at: {DateTime.Now}");
            await LoadSetter.LoadSetterInternalAsync(logger);
        }
    }
}