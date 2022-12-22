
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
using AlwaysOn.Shared.TelemetryExtensions;
using Azure.Core;
using Microsoft.ApplicationInsights;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Fluent;
using Microsoft.Azure.Cosmos.Linq;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Services
{
    public class CosmosDbService : IDatabaseService
    {
        private readonly ILogger<CosmosDbService> _logger;
        private readonly CosmosClient _dbClient;
        private readonly Container _catalogItemsContainer;
        private readonly Container _commentsContainer;
        private readonly Container _ratingsContainer;
        private readonly TelemetryClient _telemetryClient;

        private readonly CosmosLinqSerializerOptions _cosmosSerializationOptions = new CosmosLinqSerializerOptions() { PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase };

        // Expects to find the following in SysConfiguration:
        // - AzureRegion
        // - CosmosEndpointUri
        // - CosmosApiKey
        // - ComsosRetryWaitSeconds
        // - ComsosMaxRetryCount
        // - CosmosDBDatabaseName
        public CosmosDbService(
            ILogger<CosmosDbService> logger,
            SysConfiguration sysConfig,
            TelemetryClient tc,
            TokenCredential tokenCredential,
            AppInsightsCosmosRequestHandler appInsightsRequestHandler)
        {
            _logger = logger;
            _telemetryClient = tc;

            _logger.LogInformation("Initializing Cosmos DB client with endpoint {endpoint} in ApplicationRegion {azureRegion}. Database name {databaseName}", sysConfig.CosmosEndpointUri, sysConfig.AzureRegion, sysConfig.CosmosDBDatabaseName);

            CosmosClientBuilder clientBuilder = new CosmosClientBuilder(sysConfig.CosmosEndpointUri, tokenCredential)
                .WithConnectionModeDirect()
                .WithContentResponseOnWrite(false)
                .WithRequestTimeout(TimeSpan.FromSeconds(sysConfig.ComsosRequestTimeoutSeconds))
                .WithThrottlingRetryOptions(TimeSpan.FromSeconds(sysConfig.ComsosRetryWaitSeconds), sysConfig.ComsosMaxRetryCount)
                .WithCustomSerializer(new CosmosNetSerializer(Globals.JsonSerializerOptions))
                .AddCustomHandlers(appInsightsRequestHandler);

            if (sysConfig.AzureRegion != "unknown")
            {
                clientBuilder = clientBuilder.WithApplicationRegion(sysConfig.AzureRegion);
            }

            _dbClient = clientBuilder.Build();
            _catalogItemsContainer = _dbClient.GetContainer(sysConfig.CosmosDBDatabaseName, SysConfiguration.CosmosCatalogItemsContainerName);
            _commentsContainer = _dbClient.GetContainer(sysConfig.CosmosDBDatabaseName, SysConfiguration.CosmosItemCommentsContainerName);
            _ratingsContainer = _dbClient.GetContainer(sysConfig.CosmosDBDatabaseName, SysConfiguration.CosmosItemRatingsContainerName);
        }

        /// <summary>
        /// A health check that does two things:
        /// - Attempt to run a simple query
        /// - Attempt to write a dummy document to the database
        /// </summary>
        /// <returns></returns>
        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogDebug("Testing Read query to Cosmos DB");
                var iterator = _catalogItemsContainer.GetItemQueryIterator<object>("SELECT GetCurrentDateTime ()");
                _ = await iterator.ReadNextAsync(cancellationToken);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on health probe read query towards Cosmos DB");
                return new HealthCheckResult(HealthStatus.Unhealthy, exception: e);
            }

            try
            {
                _logger.LogDebug("Testing document Write to Cosmos DB");
                // Create a test document to write to cosmos
                var testRating = new ItemRating()
                {
                    Id = Guid.NewGuid(),
                    CatalogItemId = Guid.NewGuid(), // Create some random (=non-existing) item id
                    CreationDate = DateTime.UtcNow,
                    Rating = 1,
                    TimeToLive = 10 // will be auto-deleted after 10sec
                };

                await AddNewRatingAsync(testRating);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on health probe document write towards Cosmos DB");
                return new HealthCheckResult(HealthStatus.Unhealthy, exception: e);
            }

            return new HealthCheckResult(HealthStatus.Healthy);
        }

        public async Task DeleteItemAsync<T>(string objectId, string partitionKey)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            try
            {
                if (typeof(T) == typeof(CatalogItem))
                {
                    await _catalogItemsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey), requestOptions);
                }
                else if (typeof(T) == typeof(ItemComment))
                {
                    await _commentsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey), requestOptions);
                }
                else if (typeof(T) == typeof(ItemRating))
                {
                    await _ratingsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey), requestOptions);
                }
                else
                {
                    _logger.LogWarning($"Unsupported type {typeof(T).Name} for deletion");
                }
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.NotFound)
            {
                _logger.LogInformation($"{typeof(T).Name} with id {objectId} does not exist anymore and cannot be deleted.");
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
        }

        public async Task<CatalogItem> GetCatalogItemByIdAsync(Guid itemId)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            ResponseMessage responseMessage = null;
            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _catalogItemsContainer.ReadItemStreamAsync(itemId.ToString(), new PartitionKey(itemId.ToString()), requestOptions);

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    try
                    {
                        return await JsonSerializer.DeserializeAsync<CatalogItem>(responseMessage.Content, Globals.JsonSerializerOptions);
                    }
                    catch (Exception e)
                    {
                        // Translating exceptions during JSON deserialization to AlwaysOnDependencyException.
                        _logger.LogError(e, "Unknown exception on request to Cosmos DB.");
                        throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB.", innerException: e);
                    }
                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No CatalogItem found for the id/partitionkey
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetCatalogItemByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            finally
            {
                responseMessage?.Dispose();
            }
        }

        public async Task<ItemComment> GetCommentByIdAsync(Guid commentId, Guid itemId)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();
            ResponseMessage responseMessage = null;

            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _commentsContainer.ReadItemStreamAsync(commentId.ToString(), new PartitionKey(itemId.ToString()), requestOptions);

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    try
                    {
                        return await JsonSerializer.DeserializeAsync<ItemComment>(responseMessage.Content, Globals.JsonSerializerOptions);
                    }
                    catch (Exception e)
                    {
                        _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                        throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
                    }

                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No Comment found for the id/partitionkey
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetCommentByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            finally
            {
                responseMessage?.Dispose();
            }
        }

        public async Task<ItemRating> GetRatingByIdAsync(Guid ratingId, Guid itemId)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            ResponseMessage responseMessage = null;
            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _ratingsContainer.ReadItemStreamAsync(ratingId.ToString(), new PartitionKey(itemId.ToString()), requestOptions);

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    try
                    {
                        return await JsonSerializer.DeserializeAsync<ItemRating>(responseMessage.Content, Globals.JsonSerializerOptions);
                    }
                    catch (Exception e)
                    {
                        _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                        throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
                    }
                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No Comment found for the id/partitionkey
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetRatingByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            finally
            {
                responseMessage?.Dispose();
            }
        }

        /// <summary>
        /// Upserts a CatalogItem
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        /// <exception cref="AlwaysOnDependencyException"></exception>
        public async Task UpsertCatalogItemAsync(CatalogItem item)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            try
            {
                await _catalogItemsContainer.UpsertItemAsync(item, new PartitionKey(item.Id.ToString()), requestOptions);
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
        }

        /// <summary>
        /// Gets a list of documents with a specific query
        /// </summary>
        /// <returns></returns>
        /// <exception cref="AlwaysOnDependencyException"></exception>
        private async Task<IEnumerable<T>> ListDocumentsByQueryAsync<T>(IQueryable<T> queryable)
        {
            FeedIterator<T> feedIterator = queryable.ToFeedIterator();
            int readIterations = 0;
            double sumRUCharge = 0;
            var results = new List<T>();

            try
            {
                while (feedIterator.HasMoreResults)
                {
                    readIterations++;
                    var response = await feedIterator.ReadNextAsync(); // actual call to Cosmos DB to retrieve a batch of results
                    sumRUCharge += response.RequestCharge;
                    results.AddRange(response.Resource);
                }

                _logger.LogInformation("List request iterations: {readIterations}, combined RU cost: {sumRUCharge}.", readIterations, sumRUCharge);
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                feedIterator.Dispose();
            }

            return results;
        }

        public async Task AddNewCatalogItemAsync(CatalogItem item)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            try
            {
                await _catalogItemsContainer.CreateItemAsync(item, new PartitionKey(item.Id.ToString()), requestOptions);
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                _logger.LogWarning("CatalogItem with id {catalogItemId} already exists. Ignoring item", item.Id);
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
        }

        /// <summary>
        /// Gets a list of CatalogItems
        /// - Does not contain the full item, excludes properties like description
        /// </summary>
        /// <param name="limit"></param>
        /// <returns></returns>
        public async Task<IEnumerable<CatalogItem>> ListCatalogItemsAsync(int limit)
        {
            var requestOptions = CreateRequestOptionsWithOperation<QueryRequestOptions>();

            var queryable = _catalogItemsContainer.GetItemLinqQueryable<CatalogItem>(linqSerializerOptions: _cosmosSerializationOptions, requestOptions: requestOptions)
                .Select(i => new CatalogItem()
                {
                    Id = i.Id,
                    Name = i.Name,
                    ImageUrl = i.ImageUrl,
                    Price = i.Price,
                    LastUpdated = i.LastUpdated
                })
                .OrderBy(i => i.Name)
                .Take(limit);
            var result = await ListDocumentsByQueryAsync<CatalogItem>(queryable);
            return result;
        }

        public async Task<IEnumerable<ItemComment>> GetCommentsForCatalogItemAsync(Guid itemId, int limit)
        {
            var requestOptions = CreateRequestOptionsWithOperation<QueryRequestOptions>();

            var queryable = _commentsContainer.GetItemLinqQueryable<ItemComment>(linqSerializerOptions: _cosmosSerializationOptions, requestOptions: requestOptions)
                .Where(l => l.CatalogItemId == itemId)
                .OrderByDescending(c => c.CreationDate)
                .Take(limit);
            var result = await ListDocumentsByQueryAsync<ItemComment>(queryable);
            return result;
        }

        public async Task AddNewCommentAsync(ItemComment comment)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            try
            {
                await _commentsContainer.CreateItemAsync(comment, new PartitionKey(comment.CatalogItemId.ToString()), requestOptions);
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                _logger.LogWarning("ItemComment with id {CommentId} already exists. Ignoring comment", comment.Id);
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
        }

        public async Task<RatingDto> GetAverageRatingForCatalogItemAsync(Guid itemId)
        {
            var requestOptions = CreateRequestOptionsWithOperation<QueryRequestOptions>();

            FeedResponse<RatingDto> response;

            try
            {
                var queryDefintion = new QueryDefinition("SELECT AVG(c.rating) as averageRating, count(1) as numberOfVotes FROM c WHERE c.catalogItemId = @itemId")
                                                        .WithParameter("@itemId", itemId);
                var query = _ratingsContainer.GetItemQueryIterator<RatingDto>(queryDefintion, requestOptions: requestOptions);
                response = await query.ReadNextAsync();
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }

            return response?.FirstOrDefault();
        }

        public async Task AddNewRatingAsync(ItemRating rating)
        {
            var requestOptions = CreateRequestOptionsWithOperation<ItemRequestOptions>();

            try
            {
                await _ratingsContainer.CreateItemAsync(rating, new PartitionKey(rating.CatalogItemId.ToString()), requestOptions);
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                _logger.LogWarning("ItemRating with id {ratingId} already exists. Ignoring rating", rating.Id);
            }
            catch (CosmosException cex)
            {
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
        }

        /// <summary>
        /// Helper method which populates a Cosmos DB request options object with properties: "Operation" and "DbClientEndpoint" (optional).
        /// </summary>
        /// <typeparam name="T">A Cosmos DB <c>RequestOptions</c> derived type. Typically <c>ItemRequestOptions</c> or <c>QueryRequestOptions</c>.</typeparam>
        /// <param name="operationName">What will be shown as operation name in Application Insights. If not specified, CallerMemberName will be used.</param>
        /// <param name="dbClientEndpoint">Optional endpoint configured in the Cosmos Client.</param>
        /// <returns>Desired <c>RequestOptions</c> object.</returns>
        private T CreateRequestOptionsWithOperation<T>([CallerMemberName] string operationName = "") where T : RequestOptions
        {
            var dbClientEndpoint = _dbClient.Endpoint.Host;

            var props = new Dictionary<string, object>() { { "Operation", operationName } };
            if (dbClientEndpoint != null)
            {
                props.Add("DbClientEndpoint", dbClientEndpoint);
            }

            var requestOptions = Activator.CreateInstance<T>();
            requestOptions.Properties = props;

            return requestOptions;
        }
    }
}
