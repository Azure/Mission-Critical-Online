using AlwaysOn.Shared;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService.ComponentHealthChecks
{
    public class BlobStorageHealthCheck
    {
        private readonly ILogger<BlobStorageHealthCheck> _log;
        private readonly SysConfiguration _sysConfig;

        public BlobStorageHealthCheck(ILogger<BlobStorageHealthCheck> log,
            SysConfiguration sysConfig)
        {
            _log = log;
            _sysConfig = sysConfig;
        }

        /// <summary>
        /// Checks whether the state file on blob storage exists. File exists means: Healthy
        /// </summary>
        /// <returns>True=HEALTHY, False=UNHEALTHY</returns>
        public async Task<bool> GetStateBlobHealth(CancellationToken cancellationToken = default(CancellationToken))
        {
            try
            {
                var blobContainerClient = new BlobContainerClient(_sysConfig.HealthServiceStorageConnectionString, _sysConfig.HealthServiceBlobContainerName);
                _log.LogDebug("Initiated health state blob container client at {HealthBlobContainerUrl}", blobContainerClient.Uri.ToString());

                var stateBlobClient = blobContainerClient.GetBlobClient(_sysConfig.HealthServiceBlobName);
                return await stateBlobClient.ExistsAsync(cancellationToken);

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
                _log.LogError(e, "Could not check health state blob. Responding with UNHEALTHY state");
                return false;
            }
        }
    }
}
