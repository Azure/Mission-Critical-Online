using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public class LoadSettingFunctionHttp(ILogger<LoadSettingFunctionHttp> logger)
    {
        [Function(nameof(LoadSettingFunctionHttp))]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req)
        {
            var res = await LoadSetter.LoadSetterInternalAsync(logger);
            return new ObjectResult(res);
        }
    }
}
