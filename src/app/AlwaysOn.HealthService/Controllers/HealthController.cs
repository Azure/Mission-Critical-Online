using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using System;
using System.Collections.Generic;
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
        [ProducesResponseType(typeof(SummaryHealthReport), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(SummaryHealthReport), (int)HttpStatusCode.ServiceUnavailable)]
        public IActionResult GetStampLiveness()
        {
            var latestHealthReport = HealthJob.LastReport;

            // Create a simple summary report since we do not want to return the entire detailed report
            var summaryReport = new SummaryHealthReport()
            {
                LastExecution = HealthJob.LastExecution,
                Checks = latestHealthReport?.Entries.Select(e => new Check()
                {
                    Component = e.Key,
                    Status = e.Value.Status.ToString(),
                    Duration = e.Value.Duration
                }).ToList()
            };

            if (latestHealthReport?.Status == HealthStatus.Healthy)
            {
                return Ok(summaryReport);
            }
            else
            {
                return StatusCode((int)HttpStatusCode.ServiceUnavailable, summaryReport);
            }
        }
    }

    public class SummaryHealthReport
    {
        public DateTime LastExecution { get; set; }
        public List<Check> Checks { get; set; }
    }

    public class Check
    {
        public string Component { get; set; }
        public string Status { get; set; }
        public TimeSpan Duration { get; set; }
    }
}