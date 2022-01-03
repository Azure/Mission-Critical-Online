using AlwaysOn.Shared;
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using AlwaysOn.Shared.Models.DataTransfer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

namespace AlwaysOn.CatalogService
{
    public static class CatalogServiceHelpers
    {
        /// <summary>
        /// Creates a message on the message bus to request the deletion of any object by its ID
        /// Whether the object acutally exists and can be deleted is decided by the BackgroundProcessor during processing
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="logger"></param>
        /// <param name="messageProducerService"></param>
        /// <param name="objectId"></param>
        /// <param name="partitionId"></param>
        /// <returns></returns>
        public static async Task<ActionResult> DeleteObjectInternal<T>(ILogger logger, IMessageProducerService messageProducerService, Guid objectId, Guid partitionId)
        {
            var deletionRequest = new DeleteObjectRequest()
            {
                ObjectType = typeof(T).Name,
                ObjectId = objectId.ToString(),
                PartitionId = partitionId.ToString()
            };
            var messageBody = Helpers.JsonSerialize(deletionRequest);

            try
            {
                await messageProducerService.SendSingleMessageAsync(messageBody, Constants.DeleteObjectActionName);
                logger.LogInformation("DeleteObject request for type {type} was sent by the message producer objectId={objectId}", typeof(T).Name, objectId);
                return new AcceptedResult();
            }
            catch (AlwaysOnDependencyException e)
            {
                logger.LogError(e, "AlwaysOnDependencyException on sending message for objectId={objectId}, StatusCode={statusCode}", objectId, e.StatusCode);
                int responseStatusCode = e.StatusCode == HttpStatusCode.TooManyRequests ? (int)HttpStatusCode.ServiceUnavailable : (int)HttpStatusCode.InternalServerError;

                return new ObjectResult($"Error in processing. Correlation ID: {Activity.Current?.RootId}")
                {
                    StatusCode = responseStatusCode
                };
            }
            catch (Exception e)
            {
                logger.LogError(e, "Exception on sending message for objectId={objectId}", objectId);
                return new ObjectResult($"Error in processing. Correlation ID: {Activity.Current?.RootId}")
                {
                    StatusCode = (int)HttpStatusCode.InternalServerError
                };
            }
        }
    }
}
