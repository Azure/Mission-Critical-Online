using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Services
{
    public class SqlDatabaseService : IDatabaseService
    {
        private readonly AoDbContext _dbContext;
        private IMapper _mapper;

        public SqlDatabaseService(AoDbContext dbContext, IMapper mapper) => (_dbContext, _mapper) = (dbContext, mapper);

        #region CatalogItem

        public async Task<CatalogItem> GetCatalogItemByIdAsync(Guid itemId)
        {
            var res = await _dbContext
                                .CatalogItemsRead
                                .FirstOrDefaultAsync(i => i.CatalogItemId == itemId);

            return res;
        }

        public async Task AddNewCatalogItemAsync(CatalogItem catalogItem)
        {
            await UpsertCatalogItemAsync(catalogItem);
        }

        public async Task<IEnumerable<CatalogItem>> ListCatalogItemsAsync(int limit)
        {
            var res = await _dbContext
                                .CatalogItemsRead
                                .OrderBy(i => i.Name)
                                .Take(limit)
                                .ToListAsync();

            return res;
        }

        /// <summary>
        /// Handle both updates and inserts of new items. Since the database is append-only, this method will always create a new entry in the database.
        /// </summary>
        public async Task UpsertCatalogItemAsync(CatalogItem item)
        {
            var newItem = _mapper.Map<CatalogItemWrite>(item);
            newItem.CreationDate = DateTime.UtcNow; // this item will be the newest version of any other potential versions

            _dbContext.CatalogItemsWrite.Add(newItem);

            await _dbContext.SaveChangesAsync();
        }

        #endregion

        #region ItemComment

        public async Task<ItemComment> GetCommentByIdAsync(Guid commentId, Guid itemId)
        {
            var res = await _dbContext
                                .ItemCommentsRead
                                .FirstOrDefaultAsync(c => c.CommentId == commentId);

            return res;
        }

        public async Task<IEnumerable<ItemComment>> GetCommentsForCatalogItemAsync(Guid itemId, int limit)
        {
            var comments = await _dbContext
                                    .ItemCommentsRead
                                    .Where(i => i.CatalogItemId == itemId)
                                    .Take(limit)
                                    .ToListAsync();

            return comments;
        }

        public async Task AddNewCommentAsync(ItemComment comment)
        {
            var itemToAdd = _mapper.Map<ItemCommentWrite>(comment);

            _dbContext.ItemCommentsWrite.Add(itemToAdd);

            await _dbContext.SaveChangesAsync();
        }

        #endregion

        #region ItemRating

        public async Task<ItemRating> GetRatingByIdAsync(Guid ratingId, Guid itemId)
        {
            var res = await _dbContext
                                .ItemRatingsRead
                                .FirstOrDefaultAsync(r => r.RatingId == ratingId);

            return res; // null == not found
        }

        public async Task<RatingDto> GetAverageRatingForCatalogItemAsync(Guid itemId)
        {
            RatingDto avgRating = null;

            try
            {
                /*
                The following LINQ translates to SQL like this: 
                    SELECT AVG(CAST([a].[Rating] AS float)) AS [AverageRating], COUNT(*) AS [NumberOfVotes]
                    FROM [ao].[AllRatings] AS [a]
                    WHERE [a].[CatalogItemId] = @__itemId_0
                    GROUP BY [a].[CatalogItemId]
                 */
                avgRating = await _dbContext.ItemRatingsRead
                    .Where(i => i.CatalogItemId == itemId)
                    .GroupBy(i => i.CatalogItemId, r => r.Rating)
                    .Select(x => new RatingDto()
                    {
                        AverageRating = x.Average(),
                        NumberOfVotes = x.Count()
                    })
                    .FirstOrDefaultAsync();
            }
            catch (Exception e)
            {

            }

            return avgRating;
        }

        public async Task AddNewRatingAsync(ItemRating rating)
        {
            var itemToAdd = _mapper.Map<ItemRatingWrite>(rating);

            _dbContext.ItemRatingsWrite.Add(itemToAdd);

            await _dbContext.SaveChangesAsync();
        }

        #endregion

        public async Task DeleteItemAsync<T>(string itemId, string partitionKey = null)
        {
            //
            // This method uses two approaches to deletion:
            //  1. Create empty CatalogItemWrite, which contains only the bare minimum (CatalogItemId, Deleted and CreationDate) - store that in the database.
            //      - This works with the assumption that the provided ID was already validated by the caller (which it was in this case).
            //  2. Fetch the ItemComment which should be deleted first, then store it in the database with updated Deleted and CreationDate fields.
            //      - This SQL query might be unnecessary.
            //      - Also we're storing data which is not needed anymore, because the item was deleted.
            var idGuid = Guid.Parse(itemId);

            if (typeof(T) == typeof(CatalogItem))
            {
                var deletedItem = new CatalogItemWrite()
                {
                    CatalogItemId = idGuid,
                    Deleted = true,
                    CreationDate = DateTime.UtcNow,
                    Description = string.Empty,
                    Name = string.Empty,
                    ImageUrl = string.Empty,
                    Price = 0,
                    LastUpdated = DateTime.UtcNow,
                };

                _dbContext.CatalogItemsWrite.Add(deletedItem);
            }
            else if (typeof(T) == typeof(ItemCommentWrite))
            {
                var itemToDelete = await _dbContext.ItemCommentsRead.Where(i => i.CommentId == idGuid).FirstOrDefaultAsync();
                if (itemToDelete is null)
                {
                    // item was not found in the database - either doesn't exist or has been already deleted
                    // TODO: handle properly
                    return;
                }

                var deletedItem = _mapper.Map<ItemCommentWrite>(itemToDelete);
                deletedItem.CreationDate = DateTime.UtcNow;
                deletedItem.Deleted = true;
                
                _dbContext.ItemCommentsWrite.Add(deletedItem);
            }
            else if (typeof(T) == typeof(ItemRating))
            {
                var itemToDelete = await _dbContext.ItemRatingsRead.Where(i => i.RatingId == idGuid).FirstOrDefaultAsync();
                if (itemToDelete is null)
                {
                    // item was not found in the database - either doesn't exist or has been already deleted
                    // TODO: handle properly
                    return;
                }

                var deletedItem = _mapper.Map<ItemRatingWrite>(itemToDelete);
                deletedItem.CreationDate = DateTime.UtcNow;
                deletedItem.Deleted = true;

                _dbContext.ItemRatingsWrite.Add(deletedItem);
            }
            else
            {
                //_logger.LogWarning($"Unsupported type {typeof(T).Name} for deletion");
            }

            try
            {
                await _dbContext.SaveChangesAsync();
            }
            catch (Exception ex)
            {

            }
        }

        public async Task<bool> IsHealthy(CancellationToken cancellationToken = default)
        {
            // TODO: Validate if this check is enough.
            var res = await _dbContext.Database.CanConnectAsync();

            return res;
        }
        
    }
}
