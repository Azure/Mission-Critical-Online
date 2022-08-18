using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Newtonsoft.Json;
using System.Linq;
using System.Net;

namespace AlwaysOn.HealthService.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class HealthController : ControllerBase
    {
        /// <summary>
        ///     Get Health status of the healthservice itself. Just for Kubernetes
        /// </summary>
        /// <remarks>Provides an indication about the health of the API</remarks>
        [HttpGet("liveness")]
        public IActionResult GetPodLiveness()
        {
            return Ok();
        }

        /// <summary>
        ///     Get Health status of the entire stamp. Used by external systems such as FrontDoor
        /// </summary>
        /// <remarks>Provides an indication about the health of the API</remarks>
        [HttpGet("stamp")]
        [HttpHead("stamp")]
        public IActionResult GetStampLiveness()
        {
            var latestHealthReport = HealthJob.LastReport;

            var summaryReport = latestHealthReport?.Entries.Select(e => new { Component = e.Key, Status = e.Value.Status.ToString(), Duration = e.Value.Duration }).ToList();

            var json = JsonConvert.SerializeObject(latestHealthReport);
            if(latestHealthReport?.Status == HealthStatus.Healthy)
            {
                return Ok(summaryReport);
            }
            else
            {
                return StatusCode((int)HttpStatusCode.ServiceUnavailable, summaryReport);
            }
        }
    }
}