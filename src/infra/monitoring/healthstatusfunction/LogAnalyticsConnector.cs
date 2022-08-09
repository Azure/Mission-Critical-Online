using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Dynamic;
using Azure;
using Azure.Identity;
using Azure.Monitor.Query;
using Azure.Monitor.Query.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Primitives;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HealthStatusFunction
{
    class LogAnalyticsConnector
    {
        private string workspaceId;
        private string sharedKey;
        private ILogger logger;
        public LogAnalyticsConnector(string workspaceId, string sharedKey, ILogger logger) 
        {
            this.workspaceId = workspaceId;
            this.sharedKey = sharedKey;
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
            return formatLogsResult(response.Value.Table);
            //return JsonConvert.SerializeObject(response.Value.Table.Rows);
        }

        private string formatLogsResult(LogsTable table)
        {
            // In order for the result to be accepted by the DataCollector API later, it needs to have the column names in each JSON object.
            // We insert those to each row before returning the JSON array. 
            dynamic resultset = new JArray();
            foreach (LogsTableRow row in table.Rows)
            {
                dynamic rowObj = new JObject();
                for(int i=0; i<table.Columns.Count; i++)
                {
                    rowObj.Add(new JProperty(table.Columns[i].Name, row[i]));
                }
                resultset.Add(rowObj);
            }
            return JsonConvert.SerializeObject(resultset);
        }

        public async Task<bool> PostData(string logTableName, string jsonBody)
        {
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(jsonBody);
            string stringToHash = String.Format("POST\n{0}\napplication/json\nx-ms-date:{1}\n/api/logs", jsonBytes.Length, datestring);
            string hashedString = BuildSignature(stringToHash);
            string signature = string.Format("SharedKey {0}:{1}", workspaceId, hashedString);

            string url = String.Format("https://{0}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01", workspaceId);
            HttpClient httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
            httpClient.DefaultRequestHeaders.Add("Log-Type", logTableName);
            httpClient.DefaultRequestHeaders.Add("Authorization", signature);
            httpClient.DefaultRequestHeaders.Add("x-ms-date", datestring);
            httpClient.DefaultRequestHeaders.Add("time-generated-field", "TimeGenerated");

            HttpContent httpContent = new StringContent(jsonBody, Encoding.UTF8);
            httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            HttpResponseMessage response = await httpClient.PostAsync(new Uri(url), httpContent);
            logger.LogInformation("Saved {count} bytes of data to table {table} with statuscode {status}", jsonBytes.Length, logTableName, response.StatusCode);

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