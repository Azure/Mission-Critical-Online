using AlwaysOn.CatalogService.Auth;
using AlwaysOn.Shared;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Services;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Threading.Tasks;

namespace AlwaysOn.CatalogService
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

            services.AddSingleton(typeof(ITelemetryChannel),
                                new ServerTelemetryChannel() { StorageFolder = "/tmp/appinsightschannel" });
            services.AddApplicationInsightsTelemetry(Configuration[SysConfiguration.ApplicationInsightsKeyName]);

            services.AddHealthChecks();// Adds a simple liveness probe HTTP endpoint

            services.AddSingleton<IDatabaseService, CosmosDbService>();

            services.AddSingleton<IMessageProducerService, EventHubProducerService>();

            services.AddControllers().AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.DefaultIgnoreCondition = Globals.JsonSerializerOptions.DefaultIgnoreCondition;
                options.JsonSerializerOptions.PropertyNamingPolicy = Globals.JsonSerializerOptions.PropertyNamingPolicy;
            });

            // Register the Swagger generator, defining 1 or more Swagger documents
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "AlwaysOn CatalogService API", Version = "v1" });
                // Set the comments path for the Swagger JSON and UI.
                var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                c.IncludeXmlComments(xmlPath);
                c.OperationFilter<ApiKeyFilter>(); // Custom parameter in Swagger for API Key-protected operations
            });

            services.AddCors();

            services.AddSingleton<ITelemetryInitializer>(sp =>
            {
                var sysConfig = sp.GetService<SysConfiguration>();
                return new RoleNameInitializer($"{nameof(CatalogService)}-{sysConfig.AzureRegionShort}");
            });

            services.AddApiVersioning(o =>
            {
                o.ReportApiVersions = true; // enable the "api-supported-versions" header with each response
                o.AssumeDefaultVersionWhenUnspecified = true;
                o.DefaultApiVersion = new ApiVersion(1, 0);
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                // Enable middleware to serve generated Swagger as a JSON endpoint.

                // Production CatalogService API will run on the same domain as the UI, but for local development, CORS needs to be enabled.
                app.UseCors(builder => builder.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());
            }

            var sysConfig = app.ApplicationServices.GetService<SysConfiguration>();

            if (sysConfig.EnableSwagger)
            {
                app.UseSwagger();

                // Enable middleware to serve swagger-ui (HTML, JS, CSS, etc.),
                // specifying the Swagger JSON endpoint.
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "AlwaysOn CatalogService");
                });
            }

            // Handler for uncaught exceptions. Otherweise AppInsights will report a 200 for failed requests instead of 500
            // Source: https://stackoverflow.com/a/40543603/1537195
            app.UseExceptionHandler(options =>
            {
                options.Run(
                async context =>
                {
                    context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                    context.Response.ContentType = "text/html";
                    var ex = context.Features.Get<IExceptionHandlerFeature>();
                    if (ex != null)
                    {
                        //var err = $"<h1>Error: {ex.Error.Message}</h1>{ex.Error.StackTrace}";
                        var err = $"Error: {ex.Error.Message}";
                        await context.Response.WriteAsync(err).ConfigureAwait(false);
                    }
                });
            });

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
                        context.Response.Headers.Add("X-Requested-Api-Version", ctx.GetRequestedApiVersion()?.ToString());
                    }
                    return Task.CompletedTask;
                }, context);
                await next();
            });

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapHealthChecks("/health/liveness");
            });
        }
    }
}
