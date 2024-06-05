using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public static class LoadSettingFunctionHttp
    {
        [Function(nameof(LoadSettingFunctionHttp))]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
            ILogger log)
        {
            var res = await LoadSetter.LoadSetterInternalAsync(log);
            return new ObjectResult(res);
        }
    }
}
