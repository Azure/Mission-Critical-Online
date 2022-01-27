# UI Application

We decided to build a simple user interface application for AlwaysOn, which surfaces the API functionality to end users and also demonstrates how a different type of workload can be deployed to the cluster.

It's a single-page application (SPA), built with the Vue.js framework, which runs entirely in the web browser and calls the AlwaysOn APIs directly.

## How to run

### Locally

To run this app locally, make sure you have Node.js and NPM installed. Also see [Configuration](#configuration) for settings which need to be present for the app to work properly.

Then navigate to the `AlwaysOn.UI/` folder and run:

```bash
npm install
npm run serve
```

This will install all dependencies and start a development HTTP server. You can then go to http://localhost:8080/ to see the app in action.

### Production build

To build the app for deployment and production, these commands are used:

```bash
npm install
npm run build
```

This will create a deployment-ready bundle in the `./dist` folder.

### Docker

Alternatively, you can use `./Dockerfile` to build an image of this app and run it in docker.

```bash
docker build -t aoui .
docker run -p 8080:80 aoui
```

## Configuration

Configuration is handled through a static `config.js` file, which is linked directly to the page in `index.html`:

```html
<body>
  ...
  <!-- End with environmental specific config. -->
  <script src="/config.js" type="text/javascript"></script>
</body>
```

We chose this approach, because there's a need to **differentiate configuration between various environments** (`int` will have different keys and settings than `prod`).

* For **local development**: Put required settings directly into the file and use the app.
* For **cloud environment**: Azure DevOps pipeline will rewrite this file with the correct settings for a particular environment during deployment.

Alternatively, you could make the config object part of the compiled app code and let the build process populate the right values. We didn't go with this approach, because that would require to produce code artifacts for each environment and region combination.

Settings to configure:

* `window.API_URL` = URL of the API root which will be used, **without the trailing "/"**. For localhost this will be something like: *http://localhost:5000/api*, for cloud environment it will be: */api* (because the UI runs on the same domain as the API). This can also be the absolute URL of a published API, only make sure that no firewall and CORS restriction are in place.
* `window.APPINSIGHTS_INSTRUMENTATIONKEY` = Instrumentation key for the Application Insights instance to be used.

## Implementation notes

### CORS

Since this is a single-page application, running in the browser, it requires CORS (Cross-Origin Resource Sharing) to be enabled on the API, for cases when it's not running on the same root URL. The AlwaysOn application is set up in a way that it doesn't need CORS (UI running on `/` with API running on `/api`), but on localhost, this might not be the case (UI running on `localhost:8080` and API on `localhost:5000` which are considered different origins).

*Startup.cs*

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    if (env.IsDevelopment())
    {
        // ...

        // Production CatalogService API will run on the same domain, but for local development, CORS needs to be enabled.
        app.UseCors(builder => builder.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());
    }
}
```

### Headers

The CatalogService API sends back a set of additional HTTP headers, which can be used for debugging:

```http
x-correlation-id: 48cc82c400ac4d85871bcba5efb26b9e
x-server-location: North Europe
x-server-name: CatalogService-deploy-85d9fc989d-rk6gb
```

* `X-Correlation-Id` can be traced back to Application Insights.
* `X-Server-Location` represents which region served this particular request. This information helps to identify which Application Insights instance will contain the request information.
* `X-Server-Name` represents which specific pod served this particular request.

### Exceptions and error handling

The Game API returns standard HTTP responses on both success and error.

* **HTTP 200 (OK)** - request was successful and result is available immediately. Typically for GET requests which query for data.
* **HTTP 202 (Accepted)** - operation was accepted, but the result is not immediately available. This is, for example, being used for sending new comments or ratings. For these, the response contains a `Location` header representing the URL where the new item will be accessible (not applicable for ratings).
* **HTTP 400 (Bad Request)** - operation was not successful, because client provided incorrect or missing information. This can happen, for example, when required fields (like `gesture`) are not present within the request.
* **HTTP 401 (Unauthorized)** - some of the API operations require requests to provide a correct API key. Calls without this key will result in 401 errors.
* **HTTP 500 (Internal Server Error)** - operation was not successful, because server-side processing encountered an exception. There's nothing the client can do in this case. These types of errors should be caught and highlighted in the monitoring. The user may inform the operator and pass the Correlation ID in the support request.
* **HTTP 503 (Service Unavailable)** - operation was not successful, because the server is temporarily not able to fulfil. The client should retry. This can, for instance, happen when downstream components are overloaded.

For demonstration purposes, the UI application is surfacing these error codes to the page, so that it can be observed what kind of response is coming from the server.

Following the security principle of not sharing unnecessary debug information with the client, the CatalogService API provides only the Correlation ID in the failed response and doesn't share the failure reason (like an exception message).

```console
Error in processing. Correlation ID: XXXXXXXXXXXXXXXXXXXXXX.
```

With this ID (and with the help of the `X-Server-Location` header) an operator is able to investigate the incident using Application Insights.

### Data validation

The UI is currently not performing any data validation when sending requests. But invalid data will result in a 400 Bad Request response which will cause the error banner to indicate failure.

## Security

GitHub dependency scanning occasionally reveals vulnerabilities in the application. If there is a vulnerable dependency referenced within the main branch, a warning appears from [Dependabot](https://github.blog/2020-06-01-keep-all-your-packages-up-to-date-with-dependabot/):

![Dependabot warning](/docs/media/dependabot-warning.png)

One example of this occurring was with an `ssri` which is one of the Vue.js dependencies. As Dependabot was not able to deploy an automated fix and we didn't want to modify the dependency tree of a 3rd party package, there is a workaround which allows users to specify the exact package version to use.

*package.json*

```json
{
  "name": "html-ui",
  ...
  "scripts": {
    "serve": "vue-cli-service serve",
    "build": "vue-cli-service build",
    "preinstall": "npx npm-force-resolutions"
  },
  ...
  "resolutions": {
    "ssri": "8.0.1"
  }
}
```

The `resolutions` block comes from [Yarn's selective dependency resolutions](https://classic.yarnpkg.com/en/docs/selective-version-resolutions/) and is used to force specific package versions. In order to make this work with NPM there is the [NPM Force Resolutions package](https://github.com/rogeriochaves/npm-force-resolutions) which has been set up as a `preinstall` step.

> [`npx`](https://docs.npmjs.com/cli/v7/commands/npx) is short for `npm exec` and if a package is not found locally, this command installs it locally into the npm cache.

---

[Back to documentation root](/docs/README.md)
