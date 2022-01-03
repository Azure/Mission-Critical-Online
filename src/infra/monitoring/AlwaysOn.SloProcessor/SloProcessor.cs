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

namespace AlwaysOn.SloProcessor
{
    class SloProcessor
    {
        // LogName is name of the event type that is being submitted to Azure Monitor. Will be automatically suffixed with _CL
        private const string LogTableName = "SLOHistory";
        private readonly ILogger _logger;

        private readonly string _timestamp;
        private readonly HttpClient _client;


        public SloProcessor(ILogger logger)
        {
            _logger = logger;
            _timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:00.000Z");

            _client = new HttpClient();
            _client.DefaultRequestHeaders.Add("Accept", "application/json");
            _client.DefaultRequestHeaders.Add("Log-Type", LogTableName);
            _client.DefaultRequestHeaders.Add("time-generated-field", "TimeStamp");
        }
        public async Task StoreQueryResult(string workspaceId, string sharedKey, string json)
        {
            _logger.LogInformation("Received request to store query result");
            // Create a hash for the Auth signature
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(json);
            string stringToHash = "POST\n" + jsonBytes.Length + "\napplication/json\n" + "x-ms-date:" + datestring + "\n/api/logs";
            string hashedString = BuildSignature(stringToHash, sharedKey);
            string signature = "SharedKey " + workspaceId + ":" + hashedString;

            await PostData(signature, datestring, json, workspaceId);
            _logger.LogInformation("Post Data Complete");
        }

        // Send a request to the POST API endpoint
        private async Task PostData(string signature, string date, string jsonPayload, string workspaceId)
        {
            try
            {
                string url = $"https://{workspaceId}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01";

                var requestMessage = new HttpRequestMessage(HttpMethod.Post, url);
                requestMessage.Headers.Add("Authorization", signature);
                requestMessage.Headers.Add("x-ms-date", date);

                HttpContent httpContent = new StringContent(jsonPayload, Encoding.UTF8);
                httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");

                requestMessage.Content = httpContent;

                var response = await _client.SendAsync(requestMessage);

                var responseContent = response.Content;
                string result = await responseContent.ReadAsStringAsync();
                _logger.LogInformation("Post Data to Log Analytics Result: {result}", result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "API Post Exception: " + ex.Message);
            }
        }

        //Query SLO data
        public async Task<string> GetSloData(string workspaceId)
        {
            try
            {
                var msiClientId = Environment.GetEnvironmentVariable("USER_ASSIGNED_CLIENT_ID");
                var client = new LogsQueryClient(new DefaultAzureCredential(options: new DefaultAzureCredentialOptions() { ManagedIdentityClientId = msiClientId }));

                var queryString = "BackgroundProcessorSlo | union CatalogServiceSlo";

                Response<LogsQueryResult> response = await client.QueryWorkspaceAsync(
                    workspaceId,
                   queryString,
                    new QueryTimeRange(TimeSpan.FromDays(30)));

                _logger.LogInformation("Retrieved {count} rows from SLO Query '{query}'", response.Value.Table.Rows.Count, queryString);
                var rawResponsJson = response.GetRawResponse().Content.ToString();
                _logger.LogInformation("Got raw JSON: {rawResponsJson}", rawResponsJson);

                var resultTable = response.Value.Table;
                var results = new List<SloRow>();
                foreach (var row in resultTable.Rows)
                {
                    var resultRow = new SloRow() { TimeStamp = _timestamp };
                    for (int i = 0; i < row.Count; i++)
                    {
                        object item = row[i];
                        var columnName = resultTable.Columns[i].Name;

                        switch (columnName)
                        {
                            case "SloFailedTime":
                                resultRow.TotalFailureDuration = (TimeSpan)item;
                                break;
                            case "SloFailedCount":
                                resultRow.FailedCount = (long)item;
                                break;
                            case "Name":
                                resultRow.ServiceName = (string)item;
                                break;
                            case "SloPercent":
                                resultRow.SloPercentage = (double)item;
                                break;
                            case "Region":
                                resultRow.Region = (string)item;
                                break;
                        }
                    }
                    results.Add(resultRow);
                }

                var resultJson = JsonSerializer.Serialize(results);
                _logger.LogInformation("Built result JSON: {result}", resultJson);
                return resultJson;
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on SLO query execution");
                throw;
            }
        }

        // Build the Authrization signature
        private string BuildSignature(string message, string secret)
        {
            var encoding = new ASCIIEncoding();
            byte[] keyByte = Convert.FromBase64String(secret);
            byte[] messageBytes = encoding.GetBytes(message);
            using (var hmacsha256 = new HMACSHA256(keyByte))
            {
                byte[] hash = hmacsha256.ComputeHash(messageBytes);
                return Convert.ToBase64String(hash);
            }
        }

        public class SloRow
        {
            public string TimeStamp { get; set; }
            public TimeSpan TotalFailureDuration { get; set; }
            public double SloPercentage { get; set; }
            public long FailedCount { get; set; }
            public string ServiceName { get; set; }
            public string Region { get; set; }
        }
    }
}
