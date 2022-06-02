using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
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
        

        public SqlDatabaseService(AoDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task AddNewCatalogItemAsync(CatalogItemBase catalogItem)
        {
            _dbContext.CatalogItemsWrite.Add(catalogItem);

            await _dbContext.SaveChangesAsync();
        }

        public async Task AddNewCommentAsync(ItemCommentWrite comment)
        {
            _dbContext.ItemCommentsWrite.Add(comment);

            await _dbContext.SaveChangesAsync(); // check if the number of results is 1
        }

        public async Task AddNewRatingAsync(ItemRating rating)
        {
            _dbContext.ItemRatingsWrite.Add(rating);

            await _dbContext.SaveChangesAsync();
        }

        public async Task DeleteItemAsync<T>(string itemId, string partitionKey = null)
        {
            var idGuid = Guid.Parse(itemId);

            if (typeof(T) == typeof(CatalogItemWrite))
            {
                //var item = new CatalogItem() { Id = idGuid };

                var deletedItem = new CatalogItemWrite()
                {
                    CatalogItemId = idGuid,
                    Deleted = true
                };

                _dbContext.CatalogItemsWrite.Add(deletedItem);

                //_dbContext.Entry(item).State = EntityState.Deleted;
            }
            else if (typeof(T) == typeof(ItemCommentWrite))
            {
                var itemToDelete = await _dbContext.ItemCommentsRead.Where(i => i.CommentId == idGuid).FirstOrDefaultAsync();
                if (itemToDelete is null)
                {
                    // item was not found in the database - either doesn't exist or has been already deleted
                }

                var deletedItem = new ItemCommentWrite()
                {
                    AuthorName = itemToDelete.AuthorName,
                    CatalogItemId = itemToDelete.CatalogItemId,
                    CommentId = itemToDelete.CommentId,
                    CreationDate = DateTime.UtcNow,
                    Text = itemToDelete.Text,
                    Deleted = true
                };

                _dbContext.ItemCommentsWrite.Add(deletedItem);
                
                //_dbContext.Entry(item).State = EntityState.Deleted;
            }
            else if (typeof(T) == typeof(ItemRating))
            {
                var deletedItem = new ItemRating() {
                    RatingId = idGuid,
                    Deleted = true
                };

                _dbContext.ItemRatingsWrite.Add(deletedItem);
                //_dbContext.Entry(item).State = EntityState.Deleted;
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


        public async Task<RatingDto> GetAverageRatingForCatalogItemAsync(Guid itemId)
        {
            RatingDto avgRating = null;
            
            try {
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
                    .Select(x => new RatingDto() {
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

        public async Task<CatalogItemBase> GetCatalogItemByIdAsync(Guid itemId)
        {
            var res = await _dbContext
                                .CatalogItemsRead
                                .FirstOrDefaultAsync(i => i.CatalogItemId == itemId);

            return res;
        }

        public async Task<ItemCommentBase> GetCommentByIdAsync(Guid commentId, Guid itemId)
        {
            var res = await _dbContext
                                .ItemCommentsRead
                                .FirstOrDefaultAsync(c => c.CommentId == commentId);

            return res;
        }

        public async Task<IEnumerable<ItemCommentBase>> GetCommentsForCatalogItemAsync(Guid itemId, int limit)
        {
            var comments = await _dbContext
                                    .ItemCommentsRead
                                    .Where(i => i.CatalogItemId == itemId)
                                    .Take(limit)
                                    .ToListAsync();

            return comments;
        }

        public async Task<ItemRating> GetRatingByIdAsync(Guid ratingId, Guid itemId)
        {
            var res = await _dbContext
                                .ItemRatingsRead
                                .FirstOrDefaultAsync(r => r.RatingId == ratingId);

            return res; // null == not found
        }

        public async Task<bool> IsHealthy(CancellationToken cancellationToken = default)
        {
            // TODO: Validate if this check is enough.
            var res = await _dbContext.Database.CanConnectAsync();

            return res;
        }

        public async Task<IEnumerable<CatalogItemBase>> ListCatalogItemsAsync(int limit)
        {
            var res = await _dbContext
                                .CatalogItemsRead
                                .OrderBy(i => i.Name)
                                .Take(limit)
                                .ToListAsync();

            return res;
        }

        public async Task UpsertCatalogItemAsync(CatalogItemWrite item)
        {
            // check if we're tracking this entity and if not, add it
            var existingItem = _dbContext.CatalogItemsRead.Where(i => i.Id == item.Id).FirstOrDefault();
            if (existingItem == null)
            {
                _dbContext.CatalogItemsWrite.Add(item);
            }
            else
            {
                _dbContext.CatalogItemsWrite.Update(item);
            }

            await _dbContext.SaveChangesAsync();
        }
    }
}
