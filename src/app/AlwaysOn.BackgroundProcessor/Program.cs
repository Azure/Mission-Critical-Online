using AlwaysOn.BackgroundProcessor.Services;
using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Services;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Serilog;
using Serilog.Events;
using System;

namespace AlwaysOn.BackgroundProcessor
{
    public class Program
    {
        public static int Main(string[] args)
        {
            try
            {
                Log.Information($"Starting web host for {nameof(BackgroundProcessor)}");
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
            })
            .ConfigureServices((hostContext, services) =>
            {
                var appinsightsKey = hostContext.Configuration[SysConfiguration.ApplicationInsightsKeyName];
                Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                .Enrich.FromLogContext()
                .WriteTo.Console(
                        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
                .WriteTo.ApplicationInsights(appinsightsKey, TelemetryConverter.Traces, LogEventLevel.Information)
                .CreateLogger();

                services.AddSingleton<SysConfiguration>();

                services.AddSingleton<ITelemetryInitializer>(sp =>
                {
                    var sysConfig = sp.GetService<SysConfiguration>();
                    return new RoleNameInitializer($"{nameof(BackgroundProcessor)}-{sysConfig.AzureRegionShort}");
                });
                services.AddSingleton(typeof(ITelemetryChannel), new ServerTelemetryChannel() { StorageFolder = "/tmp/appinsightschannel" });
                
                services.AddApplicationInsightsTelemetryWorkerService(appinsightsKey);

                services.AddSingleton<IDatabaseService, CosmosDbService>();

                // Health check / k8s liveness probes. Source: https://stackoverflow.com/a/60722982/1537195
                services.AddHealthChecks();
                services.AddSingleton<IHealthCheckPublisher, HealthCheckPublisher>();
                services.Configure<HealthCheckPublisherOptions>(options =>
                {
                    options.Delay = TimeSpan.FromSeconds(5);
                    options.Period = TimeSpan.FromSeconds(20);
                });

                // This is where Redis could be plugged in (or other cache)
                services.AddDistributedMemoryCache();

                services.AddSingleton<ActionProcessorService>();

                // Register the actual message processor service
                services.AddHostedService<EventHubProcessorService>();
            })
            .UseSerilog();
    }
}
