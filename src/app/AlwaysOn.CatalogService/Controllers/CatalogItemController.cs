using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using AlwaysOn.CatalogService.Auth;
using AlwaysOn.Shared.Models.DataTransfer;
using AlwaysOn.Shared;
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace AlwaysOn.CatalogService.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("/api/{version:apiVersion}/[controller]")]
    public class CatalogItemController : ControllerBase
    {
        private readonly ILogger<CatalogItemController> _logger;
        private readonly IDatabaseService _databaseService;
        private readonly IMessageProducerService _messageProducerService;
        private readonly SysConfiguration _sysConfig;

        public CatalogItemController(ILogger<CatalogItemController> logger,
            IDatabaseService databaseService,
            IMessageProducerService messageProducerService,
        SysConfiguration sysConfig)
        {
            _logger = logger;
            _databaseService = databaseService;
            _messageProducerService = messageProducerService;
            _sysConfig = sysConfig;
        }

        /// <summary>
        /// Retrieves N number of CatalogItems, N defaults to 100
        /// </summary>
        /// <param name="limit"></param>
        /// <returns></returns>
        [HttpGet(Name = nameof(ListCatalogItemsAsync))]
        [ProducesResponseType(typeof(IEnumerable<CatalogItem>), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<IEnumerable<CatalogItem>>> ListCatalogItemsAsync(int limit = 100)
        {
            _logger.LogInformation("Received request to get N={limit} CatalogItems", limit);
            try
            {
                var res = await _databaseService.ListCatalogItemsAsync(limit);

                // Strip absolute location off the imageUrl (i.e. the URI of the blob storage where it is stored)
                // They will be served from a relative path, thus by Front Door
                foreach(var item in res)
                {
                    if(Uri.TryCreate(item.ImageUrl, UriKind.Absolute, out Uri imageUrl))
                    {
                        item.ImageUrl = imageUrl.LocalPath;
                    }
                }
                return Ok(res);
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on querying database, StatusCode={statusCode}", e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;
                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on querying database");
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}.");
            }
        }

        /// <summary>
        /// Gets an CatalogItem by ID
        /// </summary>
        /// <param name="itemId"></param>
        /// <returns></returns>
        [HttpGet("{itemId:guid}", Name = nameof(GetCatalogItemByIdAsync))]
        [ProducesResponseType(typeof(CatalogItem), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<CatalogItem>> GetCatalogItemByIdAsync(Guid itemId)
        {
            _logger.LogInformation("Received request to get CatalogItem {CatalogItem}", itemId);

            try
            {
                var res = await _databaseService.GetCatalogItemByIdAsync(itemId);
                // Remove absolute location off the imageUrl (i.e. the URI of the blob storage where it is stored)
                // Images will be served from a relative path, thus by Front Door
                if (Uri.TryCreate(res.ImageUrl, UriKind.Absolute, out Uri imageUrl))
                {
                    res.ImageUrl = imageUrl.LocalPath;
                }
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
        /// Creates a CatalogItem in the database
        /// </summary>
        /// <param name="itemDto"></param>
        /// <returns></returns>
        [HttpPost]
        [ProducesResponseType(typeof(CatalogItem), (int)HttpStatusCode.Created)]
        [ApiKey]
        public async Task<ActionResult<CatalogItem>> CreateNewCatalogItemAsync(CatalogItemDto itemDto)
        {
            if (string.IsNullOrEmpty(itemDto.Name) || string.IsNullOrEmpty(itemDto.Description) || itemDto.Price == null)
            {
                return BadRequest("Missing required fields");
            }

            var itemId = itemDto.Id ?? Guid.NewGuid();

            var newItem = new CatalogItem()
            {
                Id = itemId,
                Name = itemDto.Name,
                LastUpdated = DateTime.UtcNow,
                Description = itemDto.Description,
                ImageUrl = itemDto.ImageUrl,
                Price = (decimal)itemDto.Price
            };

            _logger.LogInformation("Received request to create new CatalogItemId={CatalogItemId}", itemId);
            return await UpsertCatalogItemAsync(itemId, newItem);
        }

        /// <summary>
        /// Updates a CatalogItem in the database
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="itemDto"></param>
        /// <returns></returns>
        [HttpPut("{itemId:guid}")]
        [ProducesResponseType(typeof(CatalogItem), (int)HttpStatusCode.Accepted)]
        [ApiKey]
        public async Task<ActionResult<CatalogItem>> UpdateCatalogItemAsync(Guid itemId, CatalogItemDto itemDto)
        {
            _logger.LogInformation("Received request to update CatalogItemId={CatalogItemId}", itemId);

            var existingItem = await _databaseService.GetCatalogItemByIdAsync(itemId);
            if (existingItem == null)
            {
                return StatusCode((int)HttpStatusCode.NotFound);
            }

            existingItem.Name = itemDto.Name ?? existingItem.Name;
            existingItem.Description = itemDto.Description ?? existingItem.Description;
            existingItem.Price = itemDto.Price ?? existingItem.Price;
            existingItem.ImageUrl = itemDto.ImageUrl ?? existingItem.ImageUrl;

            return await UpsertCatalogItemAsync(itemId, existingItem);
        }

        /// <summary>
        /// Upserts a catatalogItem in the database
        /// </summary>
        /// <param name="itemId"></param>
        /// <param name="item"></param>
        /// <returns></returns>
        private async Task<ActionResult<CatalogItem>> UpsertCatalogItemAsync(Guid itemId, CatalogItem item)
        {
            try
            {
                // Im imageUrl is set, download the image from that location and upload to blob storage
                if (!string.IsNullOrEmpty(item.ImageUrl))
                {
                    var imageResponse = await new HttpClient().GetAsync(item.ImageUrl);
                    var fileExtension = Path.GetExtension(item.ImageUrl) ?? "";

                    // Little special handling since our demo images come from pxhere.com and contain a "!d" as part of the extension
                    fileExtension = fileExtension?.Replace("!d", "");

                    // Download the image from source URL
                    var imageData = await imageResponse.Content.ReadAsStreamAsync();

                    var blobName = item.Id.ToString();// + fileExtension;

                    var blobClient = new BlobClient(_sysConfig.GlobalStorageAccountConnectionString,
                                                    SysConfiguration.GlobalStorageAccountImageContainerName,
                                                    blobName);

                    var options = new BlobUploadOptions()
                    {
                        Metadata = new Dictionary<string, string> { { "fileExtension", fileExtension } }
                    };

                    // Upload will overwrite (i.e. create a new verison) of any existing blob
                    await blobClient.UploadAsync(imageData, options: options);
                    _logger.LogInformation("Image was successfully uploaded to {imageBlob} for CatalogItemId={CatalogItemId}", blobClient.Uri.AbsoluteUri, item.Id);

                    // set imageUrl to the blob URI
                    item.ImageUrl = blobClient.Uri.AbsoluteUri;
                }

                await _databaseService.UpsertCatalogItemAsync(item);
                _logger.LogInformation("CatalogItemId={CatalogItemId} was upserted in the database", item.Id);
            }
            catch (AlwaysOnDependencyException e)
            {
                _logger.LogError(e, "AlwaysOnDependencyException on storing CatalogItemId={CatalogItemId}, StatusCode={statusCode}", item.Id, e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return StatusCode(responseStatusCode, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Exception on storing CatalogItemId={CatalogItemId}", item.Id);
                return StatusCode((int)HttpStatusCode.InternalServerError, $"Error in processing. Correlation ID: {Activity.Current?.RootId}");
            }

            return CreatedAtRoute(nameof(GetCatalogItemByIdAsync), new { itemId = item.Id }, item);
        }

        /// <summary>
        /// Deletes an existing CatalogItem
        /// </summary>
        /// <param name="itemId"></param>
        /// <returns></returns>
        [HttpDelete("{itemId:guid}")]
        [ProducesResponseType((int)HttpStatusCode.Accepted)]
        [ApiKey]
        public async Task<ActionResult> DeleteCatalogItemAsync(Guid itemId)
        {
            _logger.LogInformation("Received request to delete CatalogItem={CatalogItem}", itemId);
            return await CatalogServiceHelpers.DeleteObjectInternal<CatalogItem>(_logger, _messageProducerService, itemId, itemId);
        }
    }
}
