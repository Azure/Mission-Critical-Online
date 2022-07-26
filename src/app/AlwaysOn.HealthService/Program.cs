using AlwaysOn.Shared;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;
using System;

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

                // TODO: Transition Serilog AppInsights sink to use the connection string instead of Instrumentation Key, once that is fully supported
                Log.Logger = new LoggerConfiguration()
                                    .ReadFrom.Configuration(builtConfig)
                                    .Enrich.FromLogContext()
                                    .WriteTo.Console(
                                            outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
                                    .WriteTo.ApplicationInsights(builtConfig[SysConfiguration.ApplicationInsightsConnStringKeyName], TelemetryConverter.Traces)
                                    .CreateLogger();
            })
            .UseSerilog()
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder
                .UseStartup<Startup>();
            });
    }
}
