using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Services;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService
{
    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton<SysConfiguration>();
            services.AddMemoryCache();

            services.AddSingleton(typeof(ITelemetryChannel),
                                new ServerTelemetryChannel() { StorageFolder = "/tmp/appinsightschannel" });
            services.AddApplicationInsightsTelemetry(Configuration[SysConfiguration.ApplicationInsightsKeyName]);

            services.AddSingleton<IDatabaseService, CosmosDbService>();

            services.AddSingleton<IMessageProducerService, EventHubProducerService>();

            services.AddHealthChecks().AddCheck<AlwaysOnHealthCheck>(nameof(AlwaysOnHealthCheck));

            services.AddControllers().AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.DefaultIgnoreCondition = Globals.JsonSerializerOptions.DefaultIgnoreCondition;
                options.JsonSerializerOptions.PropertyNamingPolicy = Globals.JsonSerializerOptions.PropertyNamingPolicy;
            });

            // Register the Swagger generator, defining 1 or more Swagger documents
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "AlwaysOn HealthService API", Version = "v1" });
                // Set the comments path for the Swagger JSON and UI.
                var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                //c.IncludeXmlComments(xmlPath);
            });
            services.AddSingleton<ITelemetryInitializer>(sp =>
            {
                var sysConfig = sp.GetService<SysConfiguration>();
                return new RoleNameInitializer($"{nameof(HealthService)}-{sysConfig.AzureRegionShort}");
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            var sysConfig = app.ApplicationServices.GetService<SysConfiguration>();

            if (sysConfig.EnableSwagger)
            {
                app.UseSwagger();

                // Enable middleware to serve swagger-ui (HTML, JS, CSS, etc.),
                // specifying the Swagger JSON endpoint.
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "AlwaysOn HealthService");
                });
            }

            app.Use(async (context, next) =>
            {
                // Add tracing headers to each response
                // Source: https://khalidabuhakmeh.com/add-headers-to-a-response-in-aspnet-5
                context.Response.OnStarting(o =>
                {
                    if (o is HttpContext ctx)
                    {
                        context.Response.Headers.Add("X-Server-Name", Environment.MachineName);
                        context.Response.Headers.Add("X-Server-Location", sysConfig.AzureRegion);
                        context.Response.Headers.Add("X-Correlation-ID", Activity.Current?.RootId);
                    }
                    return Task.CompletedTask;
                }, context);
                await next();
            });

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
