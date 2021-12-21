# GameService

As described in the [conceptual description](/docs/reference-implementation/AppDesign-Application-Design.md), the GameService provides APIs that the UI, and all other users of the service, interact with.

## Configuration

Configuration settings are maintained in the `AlwaysOn.Shared/SysConfig.cs` file and either defined with default values there or loaded through the .NET IConfiguration provider. When running inside AKS, settings get injected via environment variables as well as through key-value files (by the [CSI secret driver for Key Vault](/src/config/charts/csi-secrets-driver)). While ENV variables are loaded automatically, to read settings from the files, we need to add this line in the `CreateHostBuilder()` method:

```csharp
config.AddKeyPerFile(directoryPath: "/mnt/secrets-store/", optional: true, reloadOnChange: true);
```

Apart from the configuration settings which are common between components, such as Cosmos DB connection settings, the following settings are used exclusively by the GameService:

- `FrontendSenderEventHubConnectionString`: Connection string with `Send` permissions to the Event Hub.
- `B2CTenantName`: Name of the Azure B2C tenant that is being used also in the UI. Expecting only the root B2C tenant name without "https://" and ".onmicrosoft.com".
- `B2CUIClientID`: Client ID of the calling application.
- `B2CPolicyName`: SignIn flow (policy) used for authentication.

## Implementation

The GameService application is based on the [.NET Core Web API](https://docs.microsoft.com/aspnet/core/web-api/?view=aspnetcore-5.0) template, using Controllers to implement the APIs.

Currently there are three API Controllers:

- `GameResultController`: This implements all the APIs to perform CRUD operations on the Game Result business objects.
- `PlayerController`: Provides APIs to fetch player statistics and game results for individual players.
- `LeaderboardController`: Implements the APIs to fetch leaderboards and to initiate the generation of a new leaderboard (the actual generation happens on the ResultWorker).

When running in development mode (set ENV `ASPNETCORE_ENVIRONMENT=Development`), the GameService exposes a Swagger interface at `/swagger` to retrieve the API definitions and execute operations for debugging.

In addition to the controllers, an [ASP.NET Core HealthCheck](https://docs.microsoft.com/aspnet/core/host-and-deploy/health-checks) is listening at `health/liveness` API which is only used by Kubernetes to probe the pod. It does not do any further checking than responding with a 200 result code.

### Dependency Injection

Wherever possible, we use Dependency Injection with interfaces for common services (for example for the message and database service). All implementations are placed in the `AlwaysOn.Shared` class library, so no package references for the actual underlying services such as Cosmos DB are required in the GameService.

### API Authorization

To demonstrate how authentication and authorization works, we [implemented Azure AD B2C](/docs/reference-implementation/AppDesign-Application-Design.md#Authentication) selectively on individual APIs within the `GameController`. There are two key initialization steps in `Startup.cs`: adding authentication and adding authorization.

**Authentication** defines "who and how" can sign in. We currently have two sign-in flows: through the UI app and directly with username and password (for simplified automated testing, called `ROPC`).

*Startup.cs*

```csharp
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        // Standard sign in flow for users.
        // Default authenticationScheme = "Bearer"
        .AddJwtBearer(jwtOptions =>
        {
            jwtOptions.Authority = $"https://{Configuration["B2C_TENANT_NAME"]}.b2clogin.com/{Configuration["B2C_TENANT_NAME"]}.onmicrosoft.com/{Configuration["B2C_SIGNIN_POLICY_NAME"]}/v2.0";
            jwtOptions.Audience = Configuration["B2C_UI_CLIENTID"]; // ClientId of the UI application
        })
        // Secondary sign in flow using the ROPC (Resource Owner Password Credentials) flow.
        .AddJwtBearer(authenticationScheme: "ROPC", jwtOptions =>
        {
            jwtOptions.Authority = $"https://{Configuration["B2C_TENANT_NAME"]}.b2clogin.com/{Configuration["B2C_TENANT_NAME"]}.onmicrosoft.com/{Configuration["B2C_ROPC_POLICY_NAME"]}/v2.0";
            jwtOptions.Audience = Configuration["B2C_UI_CLIENTID"]; // ClientId of the service application (can be the same as UI, if configured right)
        });
```

Both flows need to exist in the B2C tenant. See [B2C Provisioning](/docs/reference-implementation/Security-B2C-Provisioning.md) for details. When using `.AddJwtBearer()` more than once, the app reaches to Azure AD B2C to fetch configuration and keys for each scheme and then validates tokens using the right one. Clients specify the scheme to be used when requesting an access token from B2C:

```http
https://alwaysondev.b2clogin.com/alwaysondev.onmicrosoft.com/b2c_1_ropc_signin/oauth2/v2.0/token?client_id=xxx&username=xxx&password=xxx&grant_type=password...
```

**Authorization** specifies "what" the authenticated identity is allowed to do with the API. Once the user presents a valid access token (verified by *authentication*), the API decides whether they're allowed to carry on with the requested operation (*authorization*). To emulate elevated privileges, we introduced the custom `GameMaster` attribute which indicates if this user is allowed to perform certain operations and which is passed in the access token as an identity claim.

In .NET Core, authorization is implemented with the `[Authorize]` attribute. Although it can be applied to the whole controller, we decided to be selective and decorate only some of the API operations. During initialization, we specify what authorization policies should be used in the app:

*Startup.cs*

```csharp
services.AddAuthorization(options =>
{
    options.DefaultPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .AddAuthenticationSchemes(JwtBearerDefaults.AuthenticationScheme, "ROPC")
        .Build();

    // Check if the access token contains the "GameMaster" claim with value of "true".
    options.AddPolicy(Auth.Constants.GameMasterPolicyName, policy => policy.RequireClaim(Auth.Constants.GameMasterType, "true")); // GameMasterPolicyName = "IsGameMaster"

    // Check if the user is either a game master or an owner of particular item from the database.
    // Implemented with custom policy.
    options.AddPolicy(Auth.Constants.PlayerOrGameMasterPolicyName, policy => { // PlayerOrGameMasterPolicyName = "IsPlayerOrGameMaster"
        policy.Requirements.Add(new PlayerOrGameMasterRequirement());
    });
});
```

*Auth/GameAuthorizationHandler.cs*

```csharp
public class GameAuthorizationHandler : AuthorizationHandler<PlayerOrGameMasterRequirement, List<PlayerGesture>>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context,
                                                    PlayerOrGameMasterRequirement requirement,
                                                    List<PlayerGesture> playerGestures)
    {
        // Check if the access token contans the "GameMaster" claim with value "true".
        if (context.User.FindFirst(Constants.GameMasterType)?.Value == "true")
        {
            context.Succeed(requirement);
        }

        // Otherwise check if the requestor is one of the involved players.
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (playerGestures.Any(pg => pg.PlayerId == Guid.Parse(userId)))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
```

These policies are put to work as two forms of authorization:

1. Check if the user is a game master:

```csharp
[HttpDelete("{gameResultId:guid}")]
[ProducesResponseType((int)HttpStatusCode.Accepted)]
[Authorize(Policy = Auth.Constants.GameMasterPolicyName)] // Require authentication and block user if they're not Reviewer.
public async Task<ActionResult> DeleteGameResultAsync(Guid gameResultId)
{
    ...
}
```

2. Check if the user is involved in the game they ask for, or if they're a game master:

```csharp
[HttpGet("{gameResultId:guid}", Name = nameof(GetGameResultAsync))]
[ProducesResponseType(typeof(GameResult), (int)HttpStatusCode.OK)]
[Authorize]
public async Task<ActionResult<GameResult>> GetGameResultAsync(Guid gameResultId)
{
    ...

    var res = await _databaseService.GetGameResultByIdAsync(gameResultId);

    if (res == null)
    {
        return NotFound();
    }

    // User must be one of the players involved in the game or a Game Master to be allowed to see this game result
    var authResult = await _authorizationService.AuthorizeAsync(HttpContext.User, res.PlayerGestures, Auth.Constants.PlayerOrGameMasterPolicyName);

    if (authResult.Succeeded)
    {
        return Ok(res);
    }
    else
    {
        return Unauthorized();
    }
    ...
}
```

One special case is playing a game against the AI, using the `/ai` endpoint. The API operation requires only the selected gesture in the request body and reads current user's ID from the incoming claims:

 ```csharp
Guid playerId = Guid.Parse(HttpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value);
```

### Logging and tracing

We use the `Microsoft.ApplicationInsights.AspNetCore` NuGet package to get out-of-the-box instrumentation from the Web API. Also, [Serilog](https://github.com/serilog/serilog-extensions-logging) is used for all logging inside the application with Azure Application Insights configured as a sink (in addition to the Console sink). Only when needed to track additional metrics, we use the `TelemetryClient` for ApplicationInsights directly.

### Versioning

To demonstrate the update process, GameService implements simple API versioning on the action-level using a standard ASP.NET Core library (`Microsoft.AspNetCore.Mvc.Versioning`).

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

*GameController.cs*

```csharp
[ApiController]
[ApiVersion("1.0")] // controller supports version 1.0
[ApiVersion("2.0")] // controller supports also version 2.0
[Route("{version:apiVersion}/[controller]")] // route for updated clients with version: /1.0/game/
```

We are using attributes to declare that this controller supports two versions: 1.0 and 2.0. All action methods will default to 1.0 unless specified otherwise. This is how versioning would be implemented on action methods:

```csharp
[HttpGet("{gameResultId:guid}")]
[Authorize]
public async Task<ActionResult<GameResult>> GetGameResultAsync(Guid gameResultId)
{
    _logger.LogInformation("Received request to get game result {gameResultId}", gameResultId);
    HttpContext.Response.Headers.Add("X-Used-Api-Version", "1.0");

    return await GetGameResultByIdAsync(gameResultId);
}

[HttpGet("{gameResultId:guid}"), MapToApiVersion("2.0")]
[Authorize]
public async Task<ActionResult<GameResult>> GetGameResultAsyncV2(Guid gameResultId)
{
    _logger.LogInformation("Received v2 request to get game result {gameResultId}", 200, gameResultId);
     HttpContext.Response.Headers.Add("X-Used-Api-Version", "2.0");

    return await GetGameResultByIdAsync(gameResultId);
}
```

* Providing version string in the URL is mandatory (e.g. `https://localhost:5000/1.0/game/` or `https://ao6bd5-global-fd.azurefd.net/api/1.0/game`).
* If version is `1.0`, the first implementation will get called (`GetGameResultAsync`).
* If version is `2.0`, the second implementation will get called (`GetGameResultAsyncV2`).
* If version `3.0` is specified on the controller, but no actions map to it, first implementation will be called.

---

[Back to documentation root](/docs/README.md)
