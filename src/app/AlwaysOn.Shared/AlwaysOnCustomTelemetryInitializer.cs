using System;
using Microsoft.AspNetCore.Http;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;

namespace AlwaysOn.Shared
{
    /// <summary>Add a cloud role name to the context of every telemetries.</summary>
    /// <remarks>
    /// This allows to monitor multiple components and discriminate betweeen components.
    /// See https://docs.microsoft.com/azure/application-insights/app-insights-monitor-multi-role-apps.
    /// </remarks>
    public class AlwaysOnCustomTelemetryInitializer : ITelemetryInitializer
    {
        private readonly string _roleName;
        private readonly IHttpContextAccessor _httpContextAccessor;

        /// <summary>
        /// Construct an initializer with a role name.
        /// </summary>
        /// <param name="roleName">Cloud role name to assign to telemetry's context.</param>
        /// <param name="httpContextAccessor">Optional httpContextAccessor for HTTP request logging augmentation</param>
        /// <exception cref="ArgumentNullException"></exception>
        public AlwaysOnCustomTelemetryInitializer(string roleName, IHttpContextAccessor httpContextAccessor = null)
        {
            if (string.IsNullOrWhiteSpace(roleName))
            {
                throw new ArgumentNullException(nameof(roleName));
            }

            _roleName = roleName;
            _httpContextAccessor = httpContextAccessor;
        }

        void ITelemetryInitializer.Initialize(ITelemetry telemetry)
        {
            telemetry.Context.Cloud.RoleName = _roleName;

            if (_httpContextAccessor != null && telemetry is RequestTelemetry requestTelemetry)
            {
                requestTelemetry.Context.User.Id = _httpContextAccessor.HttpContext.Request.Headers["User-Agent"];
            }
        }
    }
}
