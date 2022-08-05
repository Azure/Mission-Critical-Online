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
            var title = request.Properties.ContainsKey("Operation") ?
                request.Properties["Operation"].ToString() :
                $"{request.Method} {request.RequestUri.OriginalString}";

            using var dependency = _telemetryClient.StartOperation<DependencyTelemetry>(title);

            //var telemetry = new DependencyTelemetry()
            //{
            //    Type = AppInsightsDependencyType,
            //    Data = $"ObjectId={objectId}, Partitionkey={partitionKey}",
            //    Name = $"Delete {typeof(T).Name}",
            //    Timestamp = startTime,
            //    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
            //    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
            //    Success = success
            //};
            //if (response != null)
            //    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

            var response = await base.SendAsync(request, cancellationToken);

            // Used to identify Cosmos DB in Application Insights
            dependency.Telemetry.Type = "Azure DocumentDB";
            dependency.Telemetry.Data = request.RequestUri.OriginalString;
            //dependency.Telemetry.Target = 

            dependency.Telemetry.ResultCode = ((int)response.StatusCode).ToString();
            dependency.Telemetry.Success = response.IsSuccessStatusCode;

            dependency.Telemetry.Metrics.Add("RequestCharge", response.Headers.RequestCharge);
            dependency.Telemetry.Metrics.Add("ClientElapsedTime", response.Diagnostics.GetClientElapsedTime().TotalMilliseconds);

            return response;
        }

        public static T CreateOptionsWithOperation<T>(string operationName) where T : RequestOptions
        {
            var requestOptions = Activator.CreateInstance<T>();
            requestOptions.Properties = new Dictionary<string, object>() { { "Operation", operationName } };

            return requestOptions;
        }
    }
}
