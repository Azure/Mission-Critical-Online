using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace GlobalOrchestrator
{
    public static class LoadSettingFunctionHttp
    {

        [FunctionName(nameof(LoadSettingFunctionHttp))]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
            ExecutionContext context,
            ILogger log)
        {
            var res = await LoadSetter.LoadSetterInternalAsync(context, log);
            return new ObjectResult(res);
        }
    }
}
