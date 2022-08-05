using Microsoft.ApplicationInsights;
using System;
using System.Collections.Generic;
using System.Net;

namespace AlwaysOn.Shared.TelemetryExtensions
{
    public static class AppInsightsExtensions
    {
        public static void TrackFailedTransaction(this TelemetryClient telemetryClient, string transactionId, HttpStatusCode statusCode, string reason, Exception? exception = null)
        {
            var properties = new Dictionary<string, string>() {
                    { "Status code", statusCode.ToString() },
                    { "Transaction ID", transactionId},
                    { "Reason", reason }
                };

            telemetryClient.TrackException(new Exception("FailedTransaction", exception), properties);
        }
    }
}
