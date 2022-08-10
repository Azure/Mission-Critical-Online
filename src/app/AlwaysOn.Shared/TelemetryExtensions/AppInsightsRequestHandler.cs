using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.Cosmos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.TelemetryExtensions
{
    /// <summary>
    /// Custom Cosmos DB request handler which automatically adds dependency tracking with <c>TelemetryClient</c> for each database request. Added metadata includes RU cost of the request.
    /// </summary>
    public class AppInsightsCosmosRequestHandler : RequestHandler
    {
        public AppInsightsCosmosRequestHandler(TelemetryClient telemetryClient)
        {
            _telemetryClient = telemetryClient;
        }

        private readonly TelemetryClient _telemetryClient;

        public override async Task<ResponseMessage> SendAsync(RequestMessage request, CancellationToken cancellationToken)
        {
            var title = request.Properties.ContainsKey("Operation") ? request.Properties["Operation"].ToString() : $"{request.Method} {request.RequestUri.OriginalString}";
            var dbClientEndpoint = request.Properties.ContainsKey("DbClientEndpoint") ? request.Properties["DbClientEndpoint"].ToString() : null;

            using var dependency = _telemetryClient.StartOperation<DependencyTelemetry>(title);

            var response = await base.SendAsync(request, cancellationToken);

            var success = response.IsSuccessStatusCode;
            // Application-specific special handling in order to have cleaner Application Insights error reporting. Client will still get proper error response.
            // There are cases which we don't consider database errors and would create noise in monitoring:
            //  - Considering NotFound as successful call to Cosmos DB, looking for a non-existent object.
            //  - The same with Conflict, which is handled the application code (ignoring the request, because it already exists).
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound || response.StatusCode == System.Net.HttpStatusCode.Conflict)
                success = true;

            dependency.Telemetry.Type = "Azure DocumentDB";
            dependency.Telemetry.Data = request.RequestUri.OriginalString; // will be shown as "Command" in Application Insights
            
            try
            {
                dependency.Telemetry.Target = response.Diagnostics != null ? response.Diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : dbClientEndpoint;
                dependency.Telemetry.ResultCode = ((int)response.StatusCode).ToString();
                dependency.Telemetry.Success = success;

                dependency.Telemetry.Metrics.Add("CosmosDbRequestUnits", response.Headers.RequestCharge);
                dependency.Telemetry.Metrics.Add("ClientElapsedTime", response.Diagnostics != null ? response.Diagnostics.GetClientElapsedTime().TotalMilliseconds : -1);

                if (request.Headers.TryGetValue("x-ms-documentdb-partitionkey", out string partitionKey))
                {
                    dependency.Telemetry.Properties.Add("PartitionKey", partitionKey);
                }
            }
            catch (Exception ex)
            {
                // Cosmos request happened, but there's something wrong with the response - e.g. missing fields on the Diagnostics object.
                // We track the issue, but still return the response afterwards.
                dependency.Telemetry.Success = false;
                dependency.Telemetry.Properties.Add("Reason", ex.Message);
                _telemetryClient.TrackException(ex);
            }

            return response;
        }
    }
}
