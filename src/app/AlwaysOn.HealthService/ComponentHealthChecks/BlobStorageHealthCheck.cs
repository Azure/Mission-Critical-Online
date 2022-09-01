using AlwaysOn.Shared;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService.ComponentHealthChecks
{
    public class BlobStorageHealthCheck : IHealthCheck
    {
        private readonly ILogger<BlobStorageHealthCheck> _logger;
        private readonly SysConfiguration _sysConfig;

        public BlobStorageHealthCheck(ILogger<BlobStorageHealthCheck> logger,
            SysConfiguration sysConfig)
        {
            _logger = logger;
            _sysConfig = sysConfig;
        }

        /// <summary>
        /// Checks whether the state file on blob storage exists. File exists means: Healthy
        /// </summary>
        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            try
            {
                var blobContainerClient = new BlobContainerClient(_sysConfig.HealthServiceStorageConnectionString, _sysConfig.HealthServiceBlobContainerName);
                _logger.LogDebug("Initiated health state blob container client at {HealthBlobContainerUrl}", blobContainerClient.Uri.ToString());

                var stateBlobClient = blobContainerClient.GetBlobClient(_sysConfig.HealthServiceBlobName);
                if (await stateBlobClient.ExistsAsync(cancellationToken))
                {
                    return new HealthCheckResult(HealthStatus.Healthy);
                }
                else
                {
                    return new HealthCheckResult(HealthStatus.Unhealthy);
                }

                /*
                 * As an alternative to just checking for the file's existence, we could also examine the file's content for specfic states
                 * For example: "HEALTHY, UNHEALTHY, MAINTENANCE"
                 * 
                var download = await stateBlobClient.DownloadAsync(cancellationToken);
                StreamReader reader = new StreamReader(download.Value.Content);
                string text = reader.ReadToEnd();

                _log.LogDebug("State blob '{stateBlobName}' present. Content: {state}", _stateBlobName, text);
                return text == "HEALTHY";
                */
            }
            catch (Exception e)
            {
                // If the file does not exist or we cannot reach our storage at all, we treat this a an unhealthy state
                // as well as it might very well mean that storage in that region has an issue.
                _logger.LogError(e, "Could not check health state blob. Responding with UNHEALTHY state");
                return new HealthCheckResult(HealthStatus.Unhealthy, exception: e);
            }
        }
    }
}
