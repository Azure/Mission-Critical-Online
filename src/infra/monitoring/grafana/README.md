# Grafana
This directory contains all the files needed for the automated provisioning of the Grafana monitoring solution. A screenshot of the full dashboard is shown at the bottom of this page.

## Contents
When the Dockerfile is built, a container is created with the following:

- Grafana
- Solution Health Dashboards
- Azure Monitor data source
- Health Model Panel plugin

## Environment Variables

The container expects the following environment variables to be set:

| Name | Value   |
|------|---------|
| GRAFANA_USERNAME | Username for the Grafana instance |
| GRAFANA_PASSWORD | Password used with username |
| AZURE_DEFAULT_SUBSCRIPTION | Id of the Azure subscription that holds the Log Analytics instances |

## Managed Identity

The data source has been set for Managed Identity authentication to Azure.
This means that the infrastructure running the container, e.g. Azure App Service, should have its system-managed identity enabled and that identity should be assigned, at minimum, the 'Log Analytics Reader' permission on a scope that includes all required Log Analytics instances.

## Grafana Authentication

Currently, authentication has been set to a username/password. Obviously this is not the best way in production scenarios, but OAuth authentication requires external dependencies that make this reference implementation harder to deploy and may be subject to security constraints in your local environment.

Before deploying this to your production environment, it is *highly recommended* to enable OAuth. This is done by editing the `grafana.ini` file and uncommenting/filling the values under the authentication section. Naturally, don't add secrets there. You can add ${MY_SECRET_VALUE} as a value and include that at runtime through environment variables.

## Grafana Health Model Panel

The Azure Mission-Critical health model has been implemented in Azure Log Analytics using KQL queries. This model is visualized using a [custom component](https://github.com/nielsams/grafanahealthmodelpanel), which is managed outside of this project and thus treated as third-party. What we discuss here is the way to use it, not the way it was built. 

### Usage

#### Input Data

The health model panel depends on a Log Analytics query result that contains the relevant information. The following columns are required in the query result:

- **ComponentName** is the name of the component as it is displayed in the health model graph.
- **Dependencies** holds a comma-separated list of components that the specific component depends on. The names should match the 'ComponentName' value of the respective component.
- **HealthScore** is used to determine the color of the visualization. The values used here should match with the threshold values described in the panel options.

As an example, the query we use in the reference implementation is:

```kql
WebsiteHealthScore
| union AddCommentUserFlowHealthScore
| union ListCatalogItemsUserFlowHealthScore
| union ShowStaticContentUserFlowHealthScore
| union PublicBlobStorageHealthScore
| union KeyvaultHealthScore
| union CatalogServiceHealthScore
| union CheckpointStorageHealthScore
| union BackgroundProcessorHealthScore
| union ClusterHealthScore
```

This gives the following result, which is the input for the health model panel:

| ComponentName            | HealthScore         | Dependencies                        |
| :----------------        | :----------         | :---------------------------------- |
| Website                  | 1                   | ListCatalogItemsUserFlow,AddCommentUserFlow |
| ListCatalogItemsUserFlow | 1                   | CatalogService,KeyVault               |
| AddCommentUserFlow       | 1                   | EventHub,BackgroundProcessor,KeyVault       |
| CatalogService           | 1                   | Cluster                             |
| BackgroundProcessor      | 1                   | Cluster                             |
| EventHub                 | 1                   |                                     |
| KeyVault                 | 1                   |                                     |
| Cluster                  | 1                   |                                     |

This query is subsequently visualized in the following way:
![Example healthmodelpanel](/docs/media/healthmodel-example.png)

## Build & Deploy

```docker build -t missioncritical-grafana .```

This docker container contains a full Grafana install as well as the health model panel and can be run directly on any container hosting environment. The required environment variable for running unsigned panels has already been set in the Dockerfile.