# Catalog Service

As described in the [conceptual description](/docs/reference-implementation/AppDesign-Application-Design.md), the CatalogService provides APIs that the UI, and all other users of the service, interact with.

## Deployment

The CatalogService application is packaged and deployed as a Helm chart. The chart is stored in the `src/app/charts` directory. It offers a set of parameters that can be used to customize the deployment (see `values.yaml` for all).

| Parameter | Description |
| --- | --- |
| scale.minReplicas | Minimum number of replicas to deploy |
| scale.maxReplicas | Maximum number of replicas to deploy |
| networkPolicy.enabled | Whether to enable network policies |
| networkPolicy.egressRange | Allowed egress range - defaults to `0.0.0.0/0` |

## Networking and Security

When CatalogService is deployed with `.Values.networkPolicy.enabled` set to `true` (default), it uses a custom network policy that allows ingress traffic (which is needed to expose the workload via the Ingress controller) and egress traffic. The egress traffic can be limited via `.Values.networkPolicy.egressRange` to for example the IP address range that contains the per-stamp Private Endpoints. It also enables ingress traffic for cert-manager (which is needed to provision certificates) and denies everything else (default deny).

> **NOTE:** The CatalogService contains a default-deny policy. When disabling NetworkPolicy per-helm chart, you've to disabled it for all charts deployed to a specific namespace.

The CatalogService container is running its workload with the non-privileged user `workload`, created as part of the image build process (see its `Dockerfile` for more). It is also configured with `readOnlyFilesystem` set to `true` to set its root filesystem `/` to read-only. This is a recommended practice for containers running workloads that are not expected to modify the filesystem. Directories requiring read-write access like `/tmp` and `/var/log` are mounted as volumes.

## Configuration

Configuration settings are maintained in the `AlwaysOn.Shared/SysConfig.cs` file and either defined with default values there or loaded through the .NET IConfiguration provider. When running inside AKS, settings get injected via environment variables as well as through key-value files (by the [CSI secret driver for Key Vault](/src/config/charts/csi-secrets-driver)). While ENV variables are loaded automatically, to read settings from the files, we need to add this line in the `CreateHostBuilder()` method:

```csharp
config.AddKeyPerFile(directoryPath: "/mnt/secrets-store/", optional: true, reloadOnChange: true);
```

Apart from the configuration settings which are common between components, such as Cosmos DB connection settings, the following settings are used exclusively by the CatalogService:

- `FrontendSenderEventHubConnectionString`: Connection string with `Send` permissions to the Event Hub.

## Implementation

The CatalogService application is based on the [.NET Core Web API](https://docs.microsoft.com/aspnet/core/web-api/?view=aspnetcore-5.0) template, using Controllers to implement the APIs.

Currently there are three API Controllers:

- `CatalogItemController`: This implements all the APIs to perform CRUD operations on the catalog item business objects.
- `CommentsController`: Provides APIs to create and fetch comments for individual catalog items.
- `RatingsController`: Provides APIs to create and fetch ratings for individual catalog items.

When running in development mode (set ENV `ASPNETCORE_ENVIRONMENT=Development`), the CatalogService exposes a Swagger interface at `/swagger` to retrieve the API definitions and execute operations for debugging.

In addition to the controllers, an [ASP.NET Core HealthCheck](https://docs.microsoft.com/aspnet/core/host-and-deploy/health-checks) is listening at `health/liveness` API which is only used by Kubernetes to probe the pod. It does not do any further checking than responding with a 200 result code.

### Dependency Injection

Wherever possible, we use Dependency Injection with interfaces for common services (for example for the message and database service). All implementations are placed in the `AlwaysOn.Shared` class library, so no package references for the actual underlying services such as Cosmos DB are required in the CatalogService.

### Logging and tracing

We use the `Microsoft.ApplicationInsights.AspNetCore` NuGet package to get out-of-the-box instrumentation from the Web API. Also, [Serilog](https://github.com/serilog/serilog-extensions-logging) is used for all logging inside the application with Azure Application Insights configured as a sink (in addition to the Console sink). Only when needed to track additional metrics, we use the `TelemetryClient` for ApplicationInsights directly.

### Versioning

To demonstrate the update process, CatalogService implements simple API versioning on the action-level using a standard ASP.NET Core library (`Microsoft.AspNetCore.Mvc.Versioning`).

*Startup.cs*

```csharp
public void ConfigureServices(IServiceCollection services)
{
    // ...
    services.AddApiVersioning(o => {
        o.ReportApiVersions = true; // return header with list of supported versions
        o.AssumeDefaultVersionWhenUnspecified = true; // support legacy clients
        o.DefaultApiVersion = new Microsoft.AspNetCore.Mvc.ApiVersion(1, 0); // default to "1.0"
    });
    // ...
}
```

*CatalogItemController.cs*

```csharp
[ApiController]
[ApiVersion("1.0")] // controller supports version 1.0
[ApiVersion("2.0")] // controller supports also version 2.0
[Route("{version:apiVersion}/[controller]")] // route for updated clients with version: /1.0/catalogitem/
```

We are using attributes to declare that this controller supports two versions: 1.0 and 2.0. All action methods will default to 1.0 unless specified otherwise. This is how versioning would be implemented on action methods:

```csharp
[HttpGet("{itemId:guid}", Name = nameof(GetCatalogItemByIdAsync))]
[ProducesResponseType(typeof(CatalogItem), (int)HttpStatusCode.OK)]
public async Task<ActionResult<CatalogItem>> GetCatalogItemByIdAsync(Guid itemId)
{
    _logger.LogDebug("Received request to get item {itemId}", itemId);
    HttpContext.Response.Headers.Add("X-Used-Api-Version", "1.0");

    return await GetCatalogItemByIdAsync(itemId);
}

[HttpGet("{itemId:guid}", Name = nameof(GetCatalogItemByIdAsync))]
[ProducesResponseType(typeof(CatalogItem), (int)HttpStatusCode.OK)]
public async Task<ActionResult<CatalogItem>> GetCatalogItemByIdAsyncV2(Guid itemId)
{
    _logger.LogDebug("Received v2 request to get get item {itemId}", itemId);
     HttpContext.Response.Headers.Add("X-Used-Api-Version", "2.0");

    return await GetCatalogItemByIdAsync(itemId);
}
```

- Providing version string in the URL is mandatory (e.g. `https://localhost:5000/1.0/catalogitem/` or `https://ao6bd5-global-fd.azurefd.net/catalogservice/api/1.0/catalogitem`).
- If version is `1.0`, the first implementation will get called (`GetCatalogItemByIdAsync`).
- If version is `2.0`, the second implementation will get called (`GetCatalogItemByIdAsyncV2`).
- If version `3.0` is specified on the controller, but no actions map to it, first implementation will be called.

### Container Image

The container image for `CatalogService` is built using a `Dockerfile` in `/src/app/AlwaysOn.CatalogService`. It's using a multi-stage process to build a lightweight container image without the overhead needed for the dotnet build process.

```docker
# Create build environment
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
...

# Create application container
FROM mcr.microsoft.com/dotnet/aspnet:6.0
...

# Copy build artifacts from previous stage build-env
COPY --from=build-env /app/AlwaysOn.CatalogService/out .
```

---

[Back to documentation root](/docs/README.md)