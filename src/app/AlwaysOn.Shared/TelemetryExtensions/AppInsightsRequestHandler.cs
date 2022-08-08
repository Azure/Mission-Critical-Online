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

            //
            // Comparison with the original telemetry object:
            //
            //var telemetry = new DependencyTelemetry()
            //{
            //    OK - Type = AppInsightsDependencyType,
            //    OK - Data = $"ObjectId={objectId}, Partitionkey={partitionKey}",
            //    OK - Name = $"Delete {typeof(T).Name}",
            //    OK - Timestamp = startTime,
            //    OK - Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
            //    OK - Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
            //    REMOVED - Success = success
            //};
            //
            //if (response != null)
            //    OK - telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

            var response = await base.SendAsync(request, cancellationToken);

            var success = response.IsSuccessStatusCode;
            // Application-specific special handling in order to have cleaner Application Insights error reporting. Client will still get proper error response.
            // There are cases which we don't consider database errors and would create noise in monitoring:
            //  - Considering NotFound as successful call to Cosmos DB, looking for a non-existent object.
            //  - The same with Conflict, which is handled the application code (ignoring the request, because it already exists).
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound || response.StatusCode == System.Net.HttpStatusCode.Conflict)
                success = true;

            dependency.Telemetry.Type = "Azure DocumentDB";
            dependency.Telemetry.Data = request.RequestUri.OriginalString; // Will be shown as "Command" in Application Insights
            dependency.Telemetry.Target = response.Diagnostics != null ? response.Diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : dbClientEndpoint;
            dependency.Telemetry.ResultCode = ((int)response.StatusCode).ToString();
            dependency.Telemetry.Success = success;

            dependency.Telemetry.Metrics.Add("CosmosDbRequestUnits", response.Headers.RequestCharge);
            dependency.Telemetry.Metrics.Add("ClientElapsedTime", response.Diagnostics != null ? response.Diagnostics.GetClientElapsedTime().TotalMilliseconds : -1);

            if (request.Headers.TryGetValue("x-ms-documentdb-partitionkey", out string partitionKey))
            {
                dependency.Telemetry.Properties.Add("PartitionKey", partitionKey);
            }

            return response;
        }

        /// <summary>
        /// Helper method which populates a Cosmos DB request options object with properties: "Operation" and "DbClientEndpoint" (optional).
        /// </summary>
        /// <typeparam name="T">A Cosmos DB <c>RequestOptions</c> derived type. Typically <c>ItemRequestOptions</c> or <c>QueryRequestOptions</c>.</typeparam>
        /// <param name="operationName">What will be shown as operation name in Application Insights.</param>
        /// <param name="dbClientEndpoint">Optional endpoint configured in the Cosmos Client.</param>
        /// <returns>Desired <c>RequestOptions</c> object.</returns>
        public static T CreateRequestOptionsWithOperation<T>(string operationName, string dbClientEndpoint = null) where T : RequestOptions
        {
            var requestOptions = Activator.CreateInstance<T>();

            var props = new Dictionary<string, object>() { { "Operation", operationName } };
            if (dbClientEndpoint != null)
            {
                props.Add("DbClientEndpoint", dbClientEndpoint);
            }

            requestOptions.Properties = props;

            return requestOptions;
        }
    }
}
