# User Interface

The User Interface (UI) is a simple frontend static HTML page with JavaScript that interacts directly with the API via REST calls.

## Hosting

The UI is compiled in the CI pipeline and uploaded to Azure Storage accounts in the CD pipeline. Each stamp hosts a storage account for hosting the UI. These Storage Accounts are enabled for [Static Website hosting](https://docs.microsoft.com/azure/storage/blobs/storage-blob-static-website) and are added as backends in Azure Front Door. The routing rule for the UI is configured with aggressive caching so that the content, even though very small, rarely needs to be loaded from storage and is otherwise directly served from Azure Front Door's edge nodes.

[Code documentation](/src/app/AlwaysOn.UI/README.md)

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
[AlwaysOn - Full List of Documentation](/docs/README.md)
