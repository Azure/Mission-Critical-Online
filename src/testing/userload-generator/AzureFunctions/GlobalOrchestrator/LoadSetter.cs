using GlobalOrchestrator.Model;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace GlobalOrchestrator
{
    public class LoadSetter
    {
        private static HttpClient _httpClient = new HttpClient();

        private const string regionalLoadgenFunctionBaseUrl = @"https://{0}.azurewebsites.net/api/StartRegionalUserflows?numberofusers={1}";

        public static async Task<List<string>> LoadSetterInternalAsync(ExecutionContext context, ILogger log)
        {
            try
            {
                string fileName = "daily_load_profile.json";

                string jsonLocation = Path.Combine(context.FunctionAppDirectory, fileName);
                string jsonString = await File.ReadAllTextAsync(jsonLocation);
                var loadProfile = JsonSerializer.Deserialize<LoadProfile>(jsonString);

                var invokedFunctions = new List<string>();

                foreach (var geo in loadProfile.geos)
                {
                    if (!geo.enabled)
                    {
                        log.LogDebug("Skipping disabled geo {geo}", geo.name);
                        continue;
                    }

                    // Get Now in the Timezone of that geo
                    DateTime geoDateNow = TimeZoneInfo.ConvertTime(DateTime.UtcNow, geo.TimeZone);
                    var geoNowTime = TimeOnly.FromDateTime(geoDateNow);

                    log.LogInformation("Start processing load profile for geo {geo}. Time of day for this geo: {geoNowTime}", geo.name, geoNowTime);

                    // Get the currently valid load profile for this geo (if there is any)
                    //  IsBetween() supports ranges that span midnight, so End can be lower than Start (e.g. 23:00-01:00)
                    var currentTimeframe = geo.timeframes
                        .Where(t => geoNowTime.IsBetween(t.Start, t.End))
                        .FirstOrDefault();

                    int currentUserLoad;

                    if (currentTimeframe != null)
                    {
                        log.LogInformation("Found current load profile {loadprofile} for current geo-time {geoTime} for geo {geo}", currentTimeframe, geoNowTime, geo.name);

                        // Check if we are still in the transition period
                        var transitionTimeEnd = currentTimeframe.Start.AddMinutes(currentTimeframe.transitionTimeMinutes);

                        if (geoNowTime.IsBetween(currentTimeframe.Start, transitionTimeEnd))
                        {
                            var minutesSinceTimeframeStart = (int)(geoNowTime - currentTimeframe.Start).TotalMinutes;

                            // Check if we need to ramp up/down from a previous timeframe which is directly adjecent to the current one
                            var previousAdjecentTimeframe = geo.timeframes.SingleOrDefault(t => t.End == currentTimeframe.Start);
                            if (previousAdjecentTimeframe != null)
                            {
                                if (previousAdjecentTimeframe.numberOfUsers != currentTimeframe.numberOfUsers)
                                {
                                    // Ramp up/down
                                    currentUserLoad = (int)Math.Round(previousAdjecentTimeframe.numberOfUsers + currentTimeframe.RampUpPerMinute(previousAdjecentTimeframe.numberOfUsers) * minutesSinceTimeframeStart);
                                }
                                else
                                {
                                    // No ramp up/down needed
                                    currentUserLoad = currentTimeframe.numberOfUsers;
                                }
                            }
                            else
                            {
                                // ramp up from 0
                                currentUserLoad = (int)Math.Round(currentTimeframe.RampUpPerMinute() * minutesSinceTimeframeStart);
                            }

                        }
                        else
                        {
                            // Apply full load once we are not in the transition time anymore
                            currentUserLoad = currentTimeframe.numberOfUsers;
                        }
                    }
                    else
                    {
                        // Turn off any load for right now
                        currentUserLoad = 0;
                        log.LogInformation("No loadProfile found for current geo-time {geoTime} for geo {geo}. Setting user load to zero", geoNowTime, geo.name);
                    }

                    log.LogInformation("Calculated current total user load for geo {geo}: {currentUserLoad}", geo.name, currentUserLoad);

                    var functionsInGeo = Environment.GetEnvironmentVariable($"FUNCTIONS_{geo.name}");
                    if (string.IsNullOrEmpty(functionsInGeo))
                    {
                        log.LogError("No Functions configured for geo {geo}", geo.name);
                        continue;
                    }

                    var functionNames = functionsInGeo.Split(",");

                    log.LogInformation("Got functions for geo {geo}: {functions}", geo.name, functionNames);

                    var usersPerGroup = DistributeIntoGroups(currentUserLoad, functionNames.Length);

                    for (int i = 0; i < functionNames.Length; i++)
                    {
                        string functionName = functionNames[i].ToUpper();
                        var functionKey = Environment.GetEnvironmentVariable($"FUNCTIONKEY_{functionName.Replace("-", "_")}"); // Env var will have underscores for any dashes
                        if (string.IsNullOrEmpty(functionKey))
                        {
                            log.LogError("No Function Key configured for Function {functionName} functionName", functionName);
                            continue;
                        }
                        var fullFunctionUrl = string.Format(regionalLoadgenFunctionBaseUrl, functionName, usersPerGroup[i]);
                        log.LogInformation("Calling Function URL: {url}", fullFunctionUrl);

                        var request = new HttpRequestMessage(HttpMethod.Get, fullFunctionUrl);
                        request.Headers.Add("x-functions-key", functionKey);

                        try
                        {
                            var response = await _httpClient.SendAsync(request);
                            log.LogInformation("HTTP response: {response}", response);
                            if (response.IsSuccessStatusCode)
                            {
                                invokedFunctions.Add(functionName);
                            }
                            else
                            {
                                log.LogWarning("Unsuccessful call to Function {function}. Status code:{code}", functionName, response.StatusCode);
                            }
                        }
                        catch (Exception e)
                        {
                            log.LogError(e, "Error calling remote Function at {url}", fullFunctionUrl);
                        }
                    }
                    log.LogInformation("Finished processing geo {geo}", geo.name);
                }
                log.LogInformation("Finished processing all geos");

                return invokedFunctions;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "General error during processing");
                throw;
            }
        }

        /// <summary>
        /// Calculates the number of users per group without any leftovers
        /// Source: https://stackoverflow.com/a/67977394/1537195
        /// </summary>
        /// <param name="sum"></param>
        /// <param name="groupsCount"></param>
        /// <returns></returns>
        private static int[] DistributeIntoGroups(int sum, int groupsCount)
        {
            var baseCount = sum / groupsCount;
            var leftover = sum % groupsCount;
            var groups = new int[groupsCount];

            for (var i = 0; i < groupsCount; i++)
            {
                groups[i] = baseCount;
                if (leftover > 0)
                {
                    groups[i]++;
                    leftover--;
                }
            }

            return groups;
        }
    }
}
