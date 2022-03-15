
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Fluent;
using Microsoft.Azure.Cosmos.Linq;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
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

        // Source: https://github.com/microsoft/ApplicationInsights-dotnet/blob/3822ab1c591298b4c0c00eb6a853265a180e8d70/WEB/Src/DependencyCollector/DependencyCollector/Implementation/RemoteDependencyConstants.cs#L3
        private const string AppInsightsDependencyType = "Azure DocumentDB";

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
            TelemetryClient tc)
        {
            _logger = logger;
            _telemetryClient = tc;

            _logger.LogInformation("Initializing Cosmos DB client with endpoint {endpoint} in ApplicationRegion {azureRegion}. Database name {databaseName}", sysConfig.CosmosEndpointUri, sysConfig.AzureRegion, sysConfig.CosmosDBDatabaseName);

            CosmosClientBuilder clientBuilder = new CosmosClientBuilder(sysConfig.CosmosEndpointUri, sysConfig.CosmosApiKey)
                .WithConnectionModeDirect()
                .WithContentResponseOnWrite(false)
                .WithRequestTimeout(TimeSpan.FromSeconds(sysConfig.ComsosRequestTimeoutSeconds))
                .WithThrottlingRetryOptions(TimeSpan.FromSeconds(sysConfig.ComsosRetryWaitSeconds), sysConfig.ComsosMaxRetryCount)
                .WithCustomSerializer(new CosmosNetSerializer(Globals.JsonSerializerOptions));

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
        public async Task<bool> IsHealthy(CancellationToken cancellationToken = default(CancellationToken))
        {
            try
            {
                _logger.LogDebug("Testing Read query to Cosmos DB");
                var iterator = _catalogItemsContainer.GetItemQueryIterator<object>("SELECT GetCurrentDateTime ()");
                var readResult = await iterator.ReadNextAsync(cancellationToken);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on health probe read query towards Cosmos DB");
                return false;
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
                return false;
            }

            return true;
        }

        public async Task DeleteItemAsync<T>(string objectId, string partitionKey)
        {
            var startTime = DateTime.UtcNow;
            ItemResponse<T> response = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            try
            {
                if (typeof(T) == typeof(CatalogItem))
                {
                    response = await _catalogItemsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey));
                }
                else if (typeof(T) == typeof(ItemComment))
                {
                    response = await _commentsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey));
                }
                else if (typeof(T) == typeof(ItemRating))
                {
                    response = await _ratingsContainer.DeleteItemAsync<T>(objectId, new PartitionKey(partitionKey));
                }
                else
                {
                    _logger.LogWarning($"Unsupported type {typeof(T).Name} for deletion");
                }

                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.NotFound)
            {
                diagnostics = cex.Diagnostics;
                _logger.LogInformation($"{typeof(T).Name} with id {objectId} does not exist anymore and cannot be deleted.");
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"ObjectId={objectId}, Partitionkey={partitionKey}",
                    Name = $"Delete {typeof(T).Name}",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                _telemetryClient.TrackDependency(telemetry);
            }
        }

        public async Task<CatalogItem> GetCatalogItemByIdAsync(Guid itemId)
        {
            string partitionKey = itemId.ToString();
            var startTime = DateTime.UtcNow;
            ResponseMessage responseMessage = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _catalogItemsContainer.ReadItemStreamAsync(
                    partitionKey: new PartitionKey(partitionKey),
                    id: itemId.ToString());
                diagnostics = responseMessage.Diagnostics;

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    var item = await JsonSerializer.DeserializeAsync<CatalogItem>(responseMessage.Content, Globals.JsonSerializerOptions);
                    success = true;
                    return item;
                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No CatalogItem found for the id/partitionkey
                    success = true;
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetCatalogItemByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"CatalogItemId={itemId}, Partitionkey={partitionKey}",
                    Name = "Get CatalogItem by Id",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success,
                    ResultCode = responseMessage.StatusCode.ToString()
                };
                if (responseMessage != null)
                {
                    telemetry.Metrics.Add("CosmosDbRequestUnits", responseMessage.Headers.RequestCharge);
                }

                _telemetryClient.TrackDependency(telemetry);
                responseMessage?.Dispose();
            }
        }

        public async Task<ItemComment> GetCommentByIdAsync(Guid commentId, Guid itemId)
        {
            string partitionKey = itemId.ToString();
            var startTime = DateTime.UtcNow;
            ResponseMessage responseMessage = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _commentsContainer.ReadItemStreamAsync(
                    partitionKey: new PartitionKey(partitionKey),
                    id: commentId.ToString());
                diagnostics = responseMessage.Diagnostics;

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    var comment = await JsonSerializer.DeserializeAsync<ItemComment>(responseMessage.Content, Globals.JsonSerializerOptions);
                    success = true;
                    return comment;
                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No Comment found for the id/partitionkey
                    success = true;
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetCommentByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"CommentId={itemId}, Partitionkey={partitionKey}",
                    Name = "Get ItemComment by Id",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success,
                    ResultCode = responseMessage.StatusCode.ToString()
                };
                if (responseMessage != null)
                {
                    telemetry.Metrics.Add("CosmosDbRequestUnits", responseMessage.Headers.RequestCharge);
                }

                _telemetryClient.TrackDependency(telemetry);
                responseMessage?.Dispose();
            }
        }

        public async Task<ItemRating> GetRatingByIdAsync(Guid ratingId, Guid itemId)
        {
            string partitionKey = itemId.ToString();
            var startTime = DateTime.UtcNow;
            ResponseMessage responseMessage = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            try
            {
                // Read the item as a stream for higher performance.
                // See: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Exceptions.md#stream-api
                responseMessage = await _ratingsContainer.ReadItemStreamAsync(
                    partitionKey: new PartitionKey(partitionKey),
                    id: ratingId.ToString());
                diagnostics = responseMessage.Diagnostics;

                // Item stream operations do not throw exceptions for better performance
                if (responseMessage.IsSuccessStatusCode)
                {
                    var rating = await JsonSerializer.DeserializeAsync<ItemRating>(responseMessage.Content, Globals.JsonSerializerOptions);
                    success = true;
                    return rating;
                }
                else if (responseMessage.StatusCode == HttpStatusCode.NotFound)
                {
                    // No Comment found for the id/partitionkey
                    success = true;
                    return null;
                }
                else
                {
                    throw new AlwaysOnDependencyException(responseMessage.StatusCode, $"Unexpected status code in {nameof(GetRatingByIdAsync)}. Code={responseMessage.StatusCode}");
                }
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"RatingId={itemId}, Partitionkey={partitionKey}",
                    Name = "Get ItemRating by Id",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success,
                    ResultCode = responseMessage.StatusCode.ToString()
                };
                if (responseMessage != null)
                {
                    telemetry.Metrics.Add("CosmosDbRequestUnits", responseMessage.Headers.RequestCharge);
                }

                _telemetryClient.TrackDependency(telemetry);
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
            string partitionKey = item.Id.ToString();
            var startTime = DateTime.UtcNow;
            var success = false;
            ItemResponse<CatalogItem> response = null;
            CosmosDiagnostics diagnostics = null;

            try
            {
                response = await _catalogItemsContainer.UpsertItemAsync(item, new PartitionKey(partitionKey));
                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"CatalogItemId={item.Id}, Partitionkey={partitionKey}",
                    Name = "Upsert CatalogItem",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                _telemetryClient.TrackDependency(telemetry);
            }
        }

        /// <summary>
        /// Gets a list of documents with a specific query
        /// </summary>
        /// <returns></returns>
        /// <exception cref="AlwaysOnDependencyException"></exception>
        private async Task<IEnumerable<T>> ListDocumentsByQueryAsync<T>(IQueryable<T> queryable)
        {
            var startTime = DateTime.UtcNow;
            var success = false;
            FeedIterator<T> feedIterator = queryable.ToFeedIterator();
            CosmosDiagnostics diagnostics = null;
            int readIterations = 0;
            double sumRUCharge = 0;
            var results = new List<T>();

            try
            {
                while (feedIterator.HasMoreResults)
                {
                    readIterations++;
                    var response = await feedIterator.ReadNextAsync(); // actual call to Cosmos DB to retrieve a batch of results
                    diagnostics = response.Diagnostics;
                    sumRUCharge += response.RequestCharge;
                    results.AddRange(response.Resource);
                }

                success = true;
            }
            catch (CosmosException cex)
            {
                success = false;
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"{queryable}",
                    Name = $"List {typeof(T).Name} items",
                    Timestamp = startTime,
                    Duration = overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };

                telemetry.Metrics.Add("CosmosDbRequestUnits", sumRUCharge);
                telemetry.Metrics.Add("ReadIterations", readIterations);
                telemetry.Metrics.Add("FetchedItemCount", results.Count);
                _telemetryClient.TrackDependency(telemetry);

                feedIterator.Dispose();
            }
            return results;
        }

        public async Task AddNewCatalogItemAsync(CatalogItem item)
        {
            var startTime = DateTime.UtcNow;
            ItemResponse<CatalogItem> response = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            var conflict = false;
            try
            {
                response = await _catalogItemsContainer.CreateItemAsync(item, new PartitionKey(item.Id.ToString()));
                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                diagnostics = cex.Diagnostics;
                _logger.LogWarning("CatalogItem with id {catalogItemId} already exists. Ignoring item", item.Id);
                conflict = true;
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"CatalogItemId={item.Id}, Partitionkey={item.Id}",
                    Name = "Add CatalogItem",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                if (conflict)
                {
                    telemetry.Properties.Add("ConflictOnInsert", conflict.ToString());
                }
                _telemetryClient.TrackDependency(telemetry);
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
            var queryable = _catalogItemsContainer.GetItemLinqQueryable<CatalogItem>(linqSerializerOptions: _cosmosSerializationOptions)
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
            var queryable = _commentsContainer.GetItemLinqQueryable<ItemComment>(linqSerializerOptions: _cosmosSerializationOptions)
                .Where(l => l.CatalogItemId == itemId)
                .OrderByDescending(c => c.CreationDate)
                .Take(limit);
            var result = await ListDocumentsByQueryAsync<ItemComment>(queryable);
            return result;
        }

        public async Task AddNewCommentAsync(ItemComment comment)
        {
            var startTime = DateTime.UtcNow;
            ItemResponse<ItemComment> response = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            var conflict = false;
            try
            {
                response = await _commentsContainer.CreateItemAsync(comment, new PartitionKey(comment.CatalogItemId.ToString()));
                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                diagnostics = cex.Diagnostics;
                _logger.LogWarning("ItemComment with id {CommentId} already exists. Ignoring comment", comment.Id);
                conflict = true;
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"CommentId={comment.Id}, Partitionkey={comment.CatalogItemId}",
                    Name = "Add Comment",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                if (conflict)
                {
                    telemetry.Properties.Add("ConflictOnInsert", conflict.ToString());
                }
                _telemetryClient.TrackDependency(telemetry);
            }
        }

        public async Task<RatingDto> GetAverageRatingForCatalogItemAsync(Guid itemId)
        {
            var startTime = DateTime.UtcNow;
            FeedResponse<RatingDto> response = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            var conflict = false;
            try
            {
                var queryDefintion = new QueryDefinition("SELECT AVG(c.rating) as averageRating, count(1) as numberOfVotes FROM c WHERE c.catalogItemId = @itemId")
                                                        .WithParameter("@itemId", itemId);
                var query = _ratingsContainer.GetItemQueryIterator<RatingDto>(queryDefintion);
                response = await query.ReadNextAsync();
                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"ItemId={itemId}",
                    Name = "Get Average Rating for CatalogItem",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                if (conflict)
                {
                    telemetry.Properties.Add("ConflictOnInsert", conflict.ToString());
                }
                _telemetryClient.TrackDependency(telemetry);
            }

            return response?.FirstOrDefault();
        }

        public async Task AddNewRatingAsync(ItemRating rating)
        {
            var startTime = DateTime.UtcNow;
            ItemResponse<ItemRating> response = null;
            CosmosDiagnostics diagnostics = null;
            var success = false;
            var conflict = false;
            try
            {
                response = await _ratingsContainer.CreateItemAsync(rating, new PartitionKey(rating.CatalogItemId.ToString()));
                diagnostics = response.Diagnostics;
                success = true;
            }
            catch (CosmosException cex) when (cex.StatusCode == HttpStatusCode.Conflict)
            {
                diagnostics = cex.Diagnostics;
                _logger.LogWarning("ItemRating with id {ratingId} already exists. Ignoring rating", rating.Id);
                conflict = true;
                success = true;
            }
            catch (CosmosException cex)
            {
                diagnostics = cex.Diagnostics;
                throw new AlwaysOnDependencyException(cex.StatusCode, innerException: cex);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unknown exception on request to Cosmos DB");
                throw new AlwaysOnDependencyException(HttpStatusCode.InternalServerError, "Unknown exception on request to Cosmos DB", innerException: e);
            }
            finally
            {
                var overallDuration = DateTime.UtcNow - startTime;
                var telemetry = new DependencyTelemetry()
                {
                    Type = AppInsightsDependencyType,
                    Data = $"ratingId={rating.Id}, Partitionkey={rating.CatalogItemId}",
                    Name = "Add Rating",
                    Timestamp = startTime,
                    Duration = diagnostics != null ? diagnostics.GetClientElapsedTime() : overallDuration,
                    Target = diagnostics != null ? diagnostics.GetContactedRegions().FirstOrDefault().uri?.Host : _dbClient.Endpoint.Host,
                    Success = success
                };
                if (response != null)
                    telemetry.Metrics.Add("CosmosDbRequestUnits", response.RequestCharge);

                if (conflict)
                {
                    telemetry.Properties.Add("ConflictOnInsert", conflict.ToString());
                }
                _telemetryClient.TrackDependency(telemetry);
            }
        }
    }
}
