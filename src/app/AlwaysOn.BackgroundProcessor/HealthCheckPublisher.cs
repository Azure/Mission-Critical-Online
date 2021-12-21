using Microsoft.Extensions.Diagnostics.HealthChecks;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.BackgroundProcessor
{
    // Source: https://stackoverflow.com/a/60722982/1537195
    public class HealthCheckPublisher : IHealthCheckPublisher
    {
        private readonly string _fileName;
        private HealthStatus _prevStatus = HealthStatus.Unhealthy;

        public HealthCheckPublisher()
        {
            _fileName = Environment.GetEnvironmentVariable("DOCKER_HEALTHCHECK_FILEPATH") ??
                        Path.GetTempFileName();
        }

        /// <summary>
        /// Creates / touches a file on the file system to indicate "healtyh" (liveness) state of the pod
        /// Deletes the files to indicate "unhealthy"
        /// The file will then be checked by k8s livenessProbe
        /// </summary>
        /// <param name="report"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public Task PublishAsync(HealthReport report, CancellationToken cancellationToken)
        {
            var fileExists = _prevStatus == HealthStatus.Healthy;

            if (report.Status == HealthStatus.Healthy)
            {
                using var _ = File.Create(_fileName);
            }
            else if (fileExists)
            {
                File.Delete(_fileName);
            }

            _prevStatus = report.Status;

            return Task.CompletedTask;
        }
    }
}
