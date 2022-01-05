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
    public class CommentsController : ControllerBase
    {
        private readonly ILogger<CommentsController> _logger;
        private readonly IDatabaseService _databaseService;
        private readonly IMessageProducerService _messageProducerService;

        public CommentsController(ILogger<CommentsController> logger,
            IDatabaseService databaseService,
            IMessageProducerService messageProducerService)
        {
            _logger = logger;
            _databaseService = databaseService;
            _messageProducerService = messageProducerService;
        }

        /// <summary>
        /// Gets an item comment by ID
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="commentId"></param>
        /// <returns></returns>
        [HttpGet("{commentId:guid}", Name = nameof(GetCommentByIdAsync))]
        [ProducesResponseType(typeof(ItemComment), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<ItemComment>> GetCommentByIdAsync([FromRoute] Guid itemId, Guid commentId)
        {
            _logger.LogInformation("Received request to get Comment {commentId}", commentId);

            try
            {
                var res = await _databaseService.GetCommentByIdAsync(commentId, itemId);
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
        /// Retrieves a list of comments for a catalogItem
        /// </summary>
        /// <returns></returns>
        [HttpGet(Name = nameof(GetCommentsByCatalogItemIdAsync))]
        [ProducesResponseType(typeof(ItemComment), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<IEnumerable<ItemComment>>> GetCommentsByCatalogItemIdAsync([FromRoute] Guid itemId, int limit = 10)
        {
            try
            {
                _logger.LogInformation("Received request to get comments for itemId={catalogItemId}", itemId.ToString());
                var res = await _databaseService.GetCommentsForCatalogItemAsync(itemId, limit);
                return res != null ? Ok(res) : NotFound();
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on querying database for catalogItemId={catalogItemId}, StatusCode={statusCode}", itemId, e.StatusCode);
                // 429 responses (Too many requests) from the downstream services we translate into 503 (service unavailable) responses to the clients. Everything else we report as 500
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on querying database for catalogItemId={catalogItemId}", itemId);
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
        }

        /// <summary>
        /// Creates a new ItemComment for a catalogItem in the database
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="commentDto"></param>
        /// <returns></returns>
        [HttpPost]
        [ProducesResponseType((int)HttpStatusCode.Accepted)]
        public async Task<ActionResult<CatalogItem>> AddNewItemCommentAsync([FromRoute] Guid itemId, [FromBody] NewCommentDto commentDto)
        {
            var comment = new ItemComment()
            {
                Id = Guid.NewGuid(),
                AuthorName = commentDto.AuthorName,
                Text = commentDto.Text,
                CreationDate = DateTime.UtcNow,
                CatalogItemId = itemId
            };
            _logger.LogInformation("Received request to create new comment with commentId={commentId} for CatalogItemId={CatalogItemId}", comment.Id, comment.CatalogItemId);

            // If this comment was sent as test data, set the TTL to a short value
            if (Request.Headers.TryGetValue("X-TEST-DATA", out var testDataHeader) && testDataHeader.FirstOrDefault()?.ToLower() == "true")
            {
                comment.TimeToLive = 30;
            }

            try
            {
                var messageBody = Helpers.JsonSerialize(comment);
                await _messageProducerService.SendSingleMessageAsync(messageBody, Constants.AddCommentActionName);
                _logger.LogInformation("AddNewCatalogItem request was sent to the message bus commentId={commentId}", comment.Id);
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on sending message for CatalogItemId={CatalogItemId}, StatusCode={statusCode}", comment.Id, e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on sending message for CatalogItemId={CatalogItemId}", comment.Id);
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }

            return AcceptedAtRoute(nameof(GetCommentByIdAsync), new { itemId = itemId, commentId = comment.Id });
        }

        /// <summary>
        /// Deletes an existing ItemComment
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="commentId"></param>
        /// <returns></returns>
        [HttpDelete("{commentId:guid}")]
        [ProducesResponseType((int)HttpStatusCode.Accepted)]
        [ApiKey]
        public async Task<ActionResult> DeleteItemCommentAsync([FromRoute] Guid itemId, Guid commentId)
        {
            _logger.LogInformation("Received request to delete ItemComment={commentId}", commentId);
            return await CatalogServiceHelpers.DeleteObjectInternal<ItemComment>(_logger, _messageProducerService, commentId, itemId);
        }
    }
}
