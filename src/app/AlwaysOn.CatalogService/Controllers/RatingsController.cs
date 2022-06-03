using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using AlwaysOn.CatalogService.Auth;
using AlwaysOn.Shared.Models.DataTransfer;
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using AlwaysOn.Shared;

namespace AlwaysOn.CatalogService.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("/api/{version:apiVersion}/CatalogItem/{itemId:guid}/[controller]")]
    public class RatingsController : ControllerBase
    {
        private readonly ILogger<RatingsController> _logger;
        private readonly IDatabaseService _databaseService;
        private readonly IMessageProducerService _messageProducerService;

        public RatingsController(ILogger<RatingsController> logger,
            IDatabaseService databaseService,
            IMessageProducerService messageProducerService)
        {
            _logger = logger;
            _databaseService = databaseService;
            _messageProducerService = messageProducerService;
        }

        /// <summary>
        /// Gets an item rating by ID
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="ratingId"></param>
        /// <returns></returns>
        [HttpGet("{ratingId:guid}", Name = nameof(GetRatingByIdAsync))]
        [ProducesResponseType(typeof(ItemRatingWrite), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<ItemRatingWrite>> GetRatingByIdAsync([FromRoute] Guid itemId, Guid ratingId)
        {
            _logger.LogDebug("Received request to get reating {ratingId}", ratingId);

            try
            {
                var res = await _databaseService.GetRatingByIdAsync(ratingId, itemId);
                return res != null ? Ok(res) : NotFound();
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on querying database, StatusCode={statusCode}", e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;
                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}.");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on querying database");
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}.");
            }
        }

        /// <summary>
        /// Retrieves the average rating for a catalogItem by its ID
        /// </summary>
        /// <returns></returns>
        [HttpGet(Name = nameof(GetRatingsForCatalogItemAsync))]
        [ProducesResponseType(typeof(RatingDto), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<RatingDto>> GetRatingsForCatalogItemAsync([FromRoute] Guid itemId)
        {
            try
            {
                _logger.LogDebug("Received request to get average rating for itemId={catalogItemId}", itemId.ToString());
                var res = await _databaseService.GetAverageRatingForCatalogItemAsync(itemId);
                return res != null ? Ok(res) : NotFound();
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on querying database for rating of catalogItemId={catalogItemId}, StatusCode={statusCode}", itemId, e.StatusCode);
                // 429 responses (Too many requests) from the downstream services we translate into 503 (service unavailable) responses to the clients. Everything else we report as 500
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on querying database for rating of catalogItemId={catalogItemId}", itemId);
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
        }

        /// <summary>
        /// Creates a new ItemRating in the database
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="ratingDto"></param>
        /// <returns></returns>
        [HttpPost]
        [ProducesResponseType((int)HttpStatusCode.Accepted)]
        public async Task<ActionResult> AddNewItemRatingAsync([FromRoute] Guid itemId, [FromBody] NewRatingDto ratingDto)
        {
            if (ratingDto.Rating < 1 || ratingDto.Rating > 5)
            {
                return BadRequest("Rating value must be between 1 and 5");
            }

            var rating = new ItemRatingWrite()
            {
                RatingId = Guid.NewGuid(),
                CreationDate = DateTime.UtcNow,
                Rating = ratingDto.Rating,
                CatalogItemId = itemId
            };
            _logger.LogDebug("Received request to create new rating with ratingId={ratingId} for CatalogItemId={CatalogItemId}", rating.Id, rating.CatalogItemId);

            // If this rating was sent as test data, set the TTL to a short value
            if (Request.Headers.TryGetValue("X-TEST-DATA", out var testDataHeader) && testDataHeader.FirstOrDefault()?.ToLower() == "true")
            {
                // TODO: Update for SQL situation.
                //rating.TimeToLive = 30;
            }

            try
            {
                var messageBody = Helpers.JsonSerialize(rating);
                await _messageProducerService.SendSingleMessageAsync(messageBody, Constants.AddRatingActionName);
                _logger.LogDebug("New rating was sent to the message bus ratingId={ratingId}", rating.Id);
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on sending rating for CatalogItemId={CatalogItemId}, StatusCode={statusCode}", rating.Id, e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on sending rating for CatalogItemId={CatalogItemId}", rating.Id);
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }

            return StatusCode((int)HttpStatusCode.Accepted);
        }

        /// <summary>
        /// Deletes an existing ItemRating
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="ratingId"></param>
        /// <returns></returns>
        [HttpDelete("{ratingId:guid}")]
        [ProducesResponseType((int)HttpStatusCode.Accepted)]
        [ApiKey]
        public async Task<ActionResult> DeleteItemRatingAsync([FromRoute] Guid itemId, Guid ratingId)
        {
            _logger.LogDebug("Received request to delete ItemRating={ratingId}", ratingId);
            return await CatalogServiceHelpers.DeleteObjectInternal<ItemRatingWrite>(_logger, _messageProducerService, ratingId, itemId);
        }
    }
}
