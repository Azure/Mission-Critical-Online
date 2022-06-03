using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
using Microsoft.ApplicationInsights;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;
using Constants = AlwaysOn.Shared.Constants;

namespace AlwaysOn.BackgroundProcessor.Services
{
    public class ActionProcessorService
    {
        private readonly ILogger<ActionProcessorService> _logger;
        private readonly TelemetryClient _telemetryClient;

        private readonly IServiceProvider _serviceProvider;


        public ActionProcessorService(ILogger<ActionProcessorService> logger, TelemetryClient tc, IServiceProvider serviceProvider)
        {
            _logger = logger;
            _telemetryClient = tc;
            // Using scoped services within a singleton as described here:
            //  https://docs.microsoft.com/en-us/dotnet/core/extensions/scoped-service
            _serviceProvider = serviceProvider;
        }

        /// <summary>
        /// Processes an serialized action message that arrived over the message bus
        /// </summary>
        public async Task Process(string action, string messageBody)
        {
            switch (action)
            {
                case Constants.AddCatalogItemActionName:
                    await AddCatalogItemAsync(messageBody);
                    break;
                case Constants.AddCommentActionName:
                    await AddItemCommentAsync(messageBody);
                    break;
                case Constants.AddRatingActionName:
                    await AddItemRatingAsync(messageBody);
                    break;
                case Constants.DeleteObjectActionName:
                    await DeleteObjectAsync(messageBody);
                    break;
                default:
                    _logger.LogWarning("Unknown event, action={action}. Ignoring message", action);
                    break;
            }
        }

        /// <summary>
        /// Handles request to delete an object from the database
        /// </summary>
        private async Task DeleteObjectAsync(string dataString)
        {
            var deletionRequest = Helpers.JsonDeserialize<DeleteObjectRequest>(dataString);
            if (deletionRequest == null)
            {
                _logger.LogError($"Could not cast data to DeleteObjectRequest");
            }
            else
            {
                try
                {
                    _logger.LogDebug("Deleting {type} from database. objectId={objectId}", deletionRequest.ObjectType, deletionRequest.ObjectId);

                    using (IServiceScope scope = _serviceProvider.CreateScope())
                    {
                        var _databaseService = scope.ServiceProvider.GetRequiredService<IDatabaseService>();

                        switch (deletionRequest.ObjectType)
                        {
                            case (nameof(CatalogItem)):
                                await _databaseService.DeleteItemAsync<CatalogItem>(deletionRequest.ObjectId, deletionRequest.PartitionId);
                                break;
                            case (nameof(ItemCommentWrite)):
                                await _databaseService.DeleteItemAsync<ItemCommentWrite>(deletionRequest.ObjectId, deletionRequest.PartitionId);
                                break;
                            case (nameof(ItemRatingWrite)):
                                await _databaseService.DeleteItemAsync<ItemRatingWrite>(deletionRequest.ObjectId, deletionRequest.PartitionId);
                                break;
                            default:
                                _logger.LogWarning("Unknown type {type} to delete", deletionRequest.ObjectType);
                                return;
                        }
                    }

                    _logger.LogInformation("Successfully deleted {type} from database. objectId={objectId}", deletionRequest.ObjectType, deletionRequest.ObjectId);
                }
                catch
                {
                    _logger.LogError("Object could not be deleted from database. objectId={objectId}", deletionRequest.ObjectId);
                    throw;
                }
            }
        }

        /// <summary>
        /// Handles request to store a new CatalogItem in the database
        /// </summary>
        private async Task AddCatalogItemAsync(string dataString)
        {
            var item = Helpers.JsonDeserialize<CatalogItemWrite>(dataString);
            if (item == null)
            {
                _logger.LogError($"Could not cast data to CatalogItem");
            }
            else
            {
                try
                {
                    _logger.LogDebug("Adding new CatalogItem to database. CatalogItemId={CatalogItemId}", item.Id);

                    using (IServiceScope scope = _serviceProvider.CreateScope())
                    {
                        var _databaseService = scope.ServiceProvider.GetRequiredService<IDatabaseService>();
                        await _databaseService.AddNewCatalogItemAsync(item);

                    }
                    _logger.LogInformation("New CatalogItem written to database. CatalogItemId={CatalogItemId}", item.Id);
                }
                catch
                {
                    _logger.LogError("CatalogItem could not be written to database. CatalogItemId={CatalogItemId}", item.Id);
                    throw;
                }
            }
        }

        /// <summary>
        /// Handles request to store a new ItemComment in the database
        /// </summary>
        private async Task AddItemCommentAsync(string dataString)
        {
            var comment = Helpers.JsonDeserialize<ItemCommentWrite>(dataString);
            if (comment == null)
            {
                _logger.LogError($"Could not cast data to ItemComment");
            }
            else
            {
                try
                {
                    _logger.LogDebug("Adding new ItemComment to database. CommentId={CommentId}", comment.Id);
                    using (IServiceScope scope = _serviceProvider.CreateScope())
                    {
                        var _databaseService = scope.ServiceProvider.GetRequiredService<IDatabaseService>();
                        await _databaseService.AddNewCommentAsync(comment);
                    }
                    _logger.LogInformation("New ItemComment written to database. CommentId={CommentId}", comment.Id);
                }
                catch
                {
                    _logger.LogError("ItemComment could not be written to database. CommentId={CommentId}", comment.Id);
                    throw;
                }
            }
        }

        /// <summary>
        /// Handles request to store a new ItemRating in the database
        /// </summary>
        private async Task AddItemRatingAsync(string dataString)
        {
            var rating = Helpers.JsonDeserialize<ItemRatingWrite>(dataString);
            if (rating == null)
            {
                _logger.LogError($"Could not cast data to ItemComment");
            }
            else
            {
                try
                {
                    _logger.LogDebug("Adding new ItemRating to database. RatingId={RatingId}", rating.Id);
                    using (IServiceScope scope = _serviceProvider.CreateScope())
                    {
                        var _databaseService = scope.ServiceProvider.GetRequiredService<IDatabaseService>();
                        await _databaseService.AddNewRatingAsync(rating);
                    }
                    _logger.LogInformation("New ItemRating written to database. RatingId={RatingId}", rating.Id);
                }
                catch
                {
                    _logger.LogError("ItemRating could not be written to database. RatingId={RatingId}", rating.Id);
                    throw;
                }
            }
        }
    }
}
