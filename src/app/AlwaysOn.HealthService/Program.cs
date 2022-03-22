using AlwaysOn.Shared;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;
using System;
using System.Text.RegularExpressions;

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

                var aiConnectionString = builtConfig[SysConfiguration.ApplicationInsightsConnStringKeyName];
                // Workaround to extract iKey from ConnectionString until Serilog fully supports the connection string method
                var aiInstrumentationKey = new Regex("InstrumentationKey=(?<key>.*);").Match(aiConnectionString)?.Groups["key"]?.Value;

                Log.Logger = new LoggerConfiguration()
                                    .ReadFrom.Configuration(builtConfig)
                                    .Enrich.FromLogContext()
                                    .WriteTo.Console(
                                            outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
                                    .WriteTo.ApplicationInsights(aiInstrumentationKey, TelemetryConverter.Traces)
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
