using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Interfaces
{
    public interface IMessageProducerService
    {
        /// <summary>
        /// Sends a single message to the message bus
        /// </summary>
        /// <param name="messageBody">String of any type that will be converted to binary and passed as the message body. Is usually expected to be JSON</param>
        /// <param name="action">Optional parameter which will be included as a message property (metadata). Used to determine how to process this message on the receiver side</param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        Task SendSingleMessageAsync(string messageBody, string action = null, CancellationToken cancellationToken = default(CancellationToken));

        /// <summary>
        /// Sends a batch of message to the message bus
        /// </summary>
        /// <param name="messages">Each message contains the messageBody as a string and optionally an action which will be included as a message property (metadata)</param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        Task SendMessageBatchAsync(IEnumerable<(string messageBody, string action)> messages, CancellationToken cancellationToken = default(CancellationToken));

        /// <summary>
        /// Healthcheck for the message bus. Attempts to send a dummy message
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        Task<bool> IsHealthy(CancellationToken cancellationToken = default(CancellationToken));
    }
}
