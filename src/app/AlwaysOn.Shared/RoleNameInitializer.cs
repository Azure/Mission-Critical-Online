using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

namespace AlwaysOn.Shared
{
    /// <summary>Add a cloud role name to the context of every telemetries.</summary>
    /// <remarks>
    /// This allows to monitor multiple components and discriminate betweeen components.
    /// See https://docs.microsoft.com/azure/application-insights/app-insights-monitor-multi-role-apps.
    /// </remarks>
    public class RoleNameInitializer : ITelemetryInitializer
    {
        private readonly string _roleName;

        /// <summary>Construct an initializer with a role name.</summary>
        /// <param name="roleName">Cloud role name to assign to telemetry's context.</param>
        public RoleNameInitializer(string roleName)
        {
            if (string.IsNullOrWhiteSpace(roleName))
            {
                throw new ArgumentNullException(nameof(roleName));
            }

            _roleName = roleName;
        }

        void ITelemetryInitializer.Initialize(ITelemetry telemetry)
        {
            telemetry.Context.Cloud.RoleName = _roleName;
        }
    }
}
