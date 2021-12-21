using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using AlwaysOn.Shared;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace AlwaysOn.HealthService.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly HealthCheckService _healthCheckService;
        private readonly SysConfiguration _sysConfig;

        public HealthController(SysConfiguration sysConfig, HealthCheckService healthCheckService)
        {
            _sysConfig = sysConfig;
            _healthCheckService = healthCheckService;
        }

        /// <summary>
        ///     Get Health status of the healthservice itself. Just for Kubernetes
        /// </summary>
        /// <remarks>Provides an indication about the health of the API</remarks>
        [HttpGet("liveness")]
        public async Task<IActionResult> GetPodLiveness()
        {
            return await Task.FromResult(Ok());
        }

        /// <summary>
        ///     Get Health status of the entire stamp. Used by external systems such as FrontDoor
        /// </summary>
        /// <remarks>Provides an indication about the health of the API</remarks>
        [HttpGet("stamp")]
        [HttpHead("stamp")]
        public async Task<IActionResult> GetStampLiveness()
        {
            var cts = new CancellationTokenSource();
            try
            {
                cts.CancelAfter(TimeSpan.FromSeconds(_sysConfig.HealthServiceOverallTimeoutSeconds));
                var report = await _healthCheckService.CheckHealthAsync(cts.Token);
                return report.Status == HealthStatus.Healthy ? Ok(report) : StatusCode((int)HttpStatusCode.ServiceUnavailable, report);
            }
            catch (TaskCanceledException)
            {
                return StatusCode((int)HttpStatusCode.ServiceUnavailable);
            }
            finally
            {
                cts.Dispose();
            }
        }
    }
}