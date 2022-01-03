using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AlwaysOn.Shared;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;
using Serilog.Events;

namespace AlwaysOn.HealthService
{
    public class Program
    {
        public static int Main(string[] args)
        {
            try
            {
                Log.Information($"Starting web host for {nameof(HealthService)}");
                CreateHostBuilder(args).Build().Run();
                return 0;
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Host terminated unexpectedly");
                return 1;
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((context, config) =>
            {
                // Load values from k8s CSI Key Vault driver mount point
                config.AddKeyPerFile(directoryPath: "/mnt/secrets-store/", optional: true, reloadOnChange: true);

                var builtConfig = config.Build();
                Log.Logger = new LoggerConfiguration()
                                    .MinimumLevel.Debug()
                                    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                                    .Enrich.FromLogContext()
                                    .Filter.ByExcluding(c => c.Properties.Any(p => p.Value.ToString().ToLower().Contains("health/liveness"))) // Exclude pod health probe from logging
                                    .WriteTo.Console(
                                            outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
                                    .WriteTo.ApplicationInsights(builtConfig[SysConfiguration.ApplicationInsightsKeyName], TelemetryConverter.Traces, LogEventLevel.Information)
                                    .CreateLogger();
            })
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder
                .UseStartup<Startup>()
                .UseSerilog();
            });
    }
}
