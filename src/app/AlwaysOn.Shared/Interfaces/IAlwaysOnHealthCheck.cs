using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Interfaces
{
    public interface IAlwaysOnHealthCheck
    {
        public string HealthCheckComponentName { get; }

        /// <summary>
        /// Health check method
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        Task<bool> IsHealthy(CancellationToken cancellationToken = default(CancellationToken));
    }
}
