using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Azure;
using Azure.Identity;
using Azure.Monitor.Query;
using Azure.Monitor.Query.Models;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HealthStatusFunction
{
    class LogAnalyticsConnector
    {
        private string workspaceId;
        private string sharedKey;
        private HttpClient httpClient;
        private ILogger logger;
        public LogAnalyticsConnector(string workspaceId, string sharedKey, ILogger logger) 
        {
            this.workspaceId = workspaceId;
            this.sharedKey = sharedKey;
            this.httpClient = new HttpClient();
            this.logger = logger;
        }

        public async Task<string> GetLogData(string query, TimeSpan timeRange)
        {
            var client = new LogsQueryClient(new DefaultAzureCredential());

            Response<LogsQueryResult> response = await client.QueryWorkspaceAsync(
                workspaceId,
                query,
                new QueryTimeRange(timeRange)
                );

            logger.LogInformation("Retrieved {count} rows from query '{query}'", response.Value.Table.Rows.Count, query);
            IReadOnlyList<LogsTableRow> result = response.Value.Table.Rows;
            return JsonConvert.SerializeObject(result);
        }

        public async Task<bool> PostData(string logTableName, string jsonBody)
        {
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(jsonBody);
            string stringToHash = String.Format("POST\n{0}\napplication/json\nx-ms-date:{1}\n/api/logs", jsonBytes.Length, datestring);
            string hashedString = BuildSignature(stringToHash);
            string signature = string.Format("SharedKey {0}:{1}", workspaceId, hashedString);

            string url = String.Format("https://{0}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01", workspaceId);
            httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
            httpClient.DefaultRequestHeaders.Add("Log-Type", logTableName);
            httpClient.DefaultRequestHeaders.Add("Authorization", signature);
            httpClient.DefaultRequestHeaders.Add("x-ms-date", datestring);
            httpClient.DefaultRequestHeaders.Add("time-generated-field", "TimeGenerated");

            HttpContent httpContent = new StringContent(jsonBody, Encoding.UTF8);
            httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            HttpResponseMessage response = await httpClient.PostAsync(new Uri(url), httpContent);

            bool result = response.IsSuccessStatusCode;
            return result;
        }

        private string BuildSignature(string message)
        {
            var encoding = new System.Text.ASCIIEncoding();
            byte[] keyByte = Convert.FromBase64String(sharedKey);
            byte[] messageBytes = encoding.GetBytes(message);
            using (var hmacsha256 = new HMACSHA256(keyByte))
            {
                byte[] hash = hmacsha256.ComputeHash(messageBytes);
                return Convert.ToBase64String(hash);
            }
        }
    }
}