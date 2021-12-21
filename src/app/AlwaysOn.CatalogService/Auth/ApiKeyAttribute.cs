using AlwaysOn.Shared;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace AlwaysOn.CatalogService.Auth
{
    /// <summary>
    /// Attribute to indicate APIs or Controllers which are protected by an API Key
    /// Source: http://codingsonata.com/secure-asp-net-core-web-api-using-api-key-authentication/
    /// </summary>
    [AttributeUsage(validOn: AttributeTargets.Class | AttributeTargets.Method)]
    public class ApiKeyAttribute : Attribute, IAsyncActionFilter
    {
        public const string APIKEYNAME = "X-API-KEY";
        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            if (!context.HttpContext.Request.Headers.TryGetValue(APIKEYNAME, out var extractedApiKey))
            {
                context.Result = new ContentResult()
                {
                    StatusCode = 401,
                    Content = "Api Key was not provided"
                };
                return;
            }

            var sysConfiguration = context.HttpContext.RequestServices.GetRequiredService<SysConfiguration>();

            var apiKey = sysConfiguration.ApiKey;

            if (!extractedApiKey.Equals(apiKey))
            {
                context.Result = new ContentResult()
                {
                    StatusCode = 401,
                    Content = "Api Key is not valid"
                };
                return;
            }

            await next();
        }
    }

    /// <summary>
    /// Swagger OperationFilter so that Swagger includes the API Key header as a required parameter for the marked APIs
    /// </summary>
    public class ApiKeyFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var filterDescriptors = context.ApiDescription.ActionDescriptor.FilterDescriptors;
            // If the operation is marked with the ApiKeyAttribute, add the x-api-key as a parameter
            if (filterDescriptors.Any(f => f.Filter is ApiKeyAttribute))
            {
                operation.Parameters.Add(new OpenApiParameter()
                {
                    Name = ApiKeyAttribute.APIKEYNAME.ToLower(),
                    In = ParameterLocation.Header,
                    Required = true,
                    Description = "API Key for restricted operations",
                    Style = ParameterStyle.Simple,
                    Schema = new OpenApiSchema()
                    {
                        Type = "string"
                    }
                });
            }
        }
    }
}
