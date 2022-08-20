using AlwaysOn.Shared;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService
{
    /// <summary>
    /// Background job that performs the health checks on a regular interval and caches the result in memory
    /// Initial source: https://stackoverflow.com/a/68630985/1537195
    /// </summary>
    public class HealthJob : BackgroundService
    {
        private readonly TimeSpan _checkInterval;

        private readonly HealthCheckService _healthCheckService;
        private readonly SysConfiguration _sysConfig;

        public static HealthReport LastReport { get; private set; }
        public static DateTime LastExecution { get; private set; }

        public HealthJob(SysConfiguration sysConfig, HealthCheckService healthCheckService)
        {
            _sysConfig = sysConfig;
            _healthCheckService = healthCheckService;
            _checkInterval = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var cts = new CancellationTokenSource(TimeSpan.FromSeconds(_sysConfig.HealthServiceOverallTimeoutSeconds));
                try
                {
                    // Run all health checks
                    LastReport = await _healthCheckService.CheckHealthAsync(cts.Token);
                    LastExecution = DateTime.Now;
                }
                catch (TaskCanceledException)
                {
                    // Ignored
                }
                catch (Exception e)
                {
                    var exceptionEntry = new HealthReportEntry(HealthStatus.Unhealthy, "Exception on running health checks", TimeSpan.Zero, e, null);
                    var entries = new Dictionary<string, HealthReportEntry>
                    {
                        { "HealthCheckerError", exceptionEntry }
                    };

                    LastReport = new HealthReport(entries, TimeSpan.Zero);
                }
                finally
                {
                    cts.Dispose();
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }
        }
    }
}
