using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;

namespace AlwaysOn.Shared.Interfaces
{
    public interface IDatabaseService
    {
        /// <summary>
        /// Get a specific catalogItem by its ID
        /// </summary>
        /// <param name="itemId"></param>
        /// <returns></returns>
        Task<CatalogItem> GetCatalogItemByIdAsync(Guid itemId);

        /// <summary>
        /// Writes a new CatalogItem to the database
        /// </summary>
        /// <param name="catalogItem"></param>
        /// <returns></returns>
        Task AddNewCatalogItemAsync(CatalogItem catalogItem);

        /// <summary>
        /// Fetches N number of CatalogItem
        /// </summary>
        /// <param name="limit"></param>
        /// <returns></returns>
        Task<IEnumerable<CatalogItem>> ListCatalogItemsAsync(int limit);

        /// <summary>
        /// Upserts CatalogItem
        /// </summary>
        /// <param name="item">Full CatalogItem object to be updated</param>
        /// <returns></returns>
        Task UpsertCatalogItemAsync(CatalogItem item);

        /// <summary>
        /// Fetches latest comments for a given catalogItem
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="limit"></param>
        /// <returns></returns>
        Task<IEnumerable<ItemComment>> GetCommentsForCatalogItemAsync(Guid itemId, int limit);

        /// <summary>
        /// Writes a new ItemComment to the database
        /// </summary>
        /// <param name="catalogItem"></param>
        /// <returns></returns>
        Task AddNewCommentAsync(ItemComment comment);

        /// <summary>
        /// Gets a specific ItemRating by its ID and the CatalogItemId
        /// </summary>
        /// <param name="ratingId"></param>
        /// <param name="itemId"></param>
        /// <returns></returns>
        Task<ItemRating> GetRatingByIdAsync(Guid ratingId, Guid itemId);

        /// <summary>
        /// Gets a specific ItemComment by its ID and the CatalogItemId
        /// </summary>
        /// <param name="ratingId"></param>
        /// <param name="itemId"></param>
        /// <returns></returns>
        Task<ItemComment> GetCommentByIdAsync(Guid commentId, Guid itemId);

        /// <summary>
        /// Get the average rating for a given catalogItem
        /// </summary>
        /// <param name="itemId"></param>
        /// <returns></returns>
        Task<RatingDto> GetAverageRatingForCatalogItemAsync(Guid itemId);

        /// <summary>
        /// Writes a new ItemRating to the database
        /// </summary>
        /// <param name="rating"></param>
        /// <returns></returns>
        Task AddNewRatingAsync(ItemRating rating);

        /// <summary>
        /// Deletes a given object from the database by ID
        /// </summary>
        /// <param name="objectId">Unique identifier of the object</param>
        /// <param name="partitionKey">partition key for the given object. Can be null for database engines which don't use partition keys.</param>
        /// <returns></returns>
        Task DeleteItemAsync<T>(string objectId, string partitionKey = null);

        /// <summary>
        /// Health check for the database service
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        Task<bool> IsHealthy(CancellationToken cancellationToken = default(CancellationToken));
    }
}
