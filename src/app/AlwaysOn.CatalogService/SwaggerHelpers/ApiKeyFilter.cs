using AlwaysOn.CatalogService.Auth;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Linq;

namespace AlwaysOn.CatalogService.SwaggerHelpers
{
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
