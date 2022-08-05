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
    public class AppInsightsRequestHandler : RequestHandler
    {
        public AppInsightsRequestHandler(TelemetryClient telemetryClient)
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

            dependency.Telemetry.Type = "Azure DocumentDB";
            dependency.Telemetry.Data = request.RequestUri.OriginalString; // Will be shown as "Command" in Application Insights
            dependency.Telemetry.Target = response.Diagnostics != null ? response.Diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : dbClientEndpoint;
            dependency.Telemetry.ResultCode = ((int)response.StatusCode).ToString();
            dependency.Telemetry.Success = response.IsSuccessStatusCode;

            dependency.Telemetry.Metrics.Add("CosmosDbRequestUnits", response.Headers.RequestCharge);
            dependency.Telemetry.Metrics.Add("ClientElapsedTime", response.Diagnostics != null ? response.Diagnostics.GetClientElapsedTime().TotalMilliseconds : -1);

            if (request.Headers.TryGetValue("x-ms-documentdb-partitionkey", out string partitionKey))
            {
                dependency.Telemetry.Properties.Add("PartitionKey", partitionKey);
            }

            return response;
        }

        public static T CreateOptionsWithOperation<T>(string operationName, string dbClientEndpoint = null) where T : RequestOptions
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
