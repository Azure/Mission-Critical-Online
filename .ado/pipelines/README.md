# Azure DevOps Workflows

As explained in the [DevOps design decisions](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-deploy-test#deployment-devops) section, the Azure Mission-Critical online reference implementation is using Azure Pipelines to implement CI/CD pipelines. Azure Pipelines is part of the Azure DevOps (ADO) service and used to automate all build and release tasks.

## Pipelines

The Azure Mission-Critical project consists of multiple pipelines automating various aspects and tasks needed to deploy and operate Azure Mission-Critical. The pipelines to release INT, PROD and E2E are basically identical (with a few different parameters). They are the implementation of the [Zero-downtime deployment strategy](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-deploy-test#deployment-zero-downtime-updates):

- **Azure.AlwaysOn INT Release** (`azure-release-int.yaml`) deploys and updates the entire solution for the INT environment.

- **Azure.AlwaysOn PROD Release** (`azure-release-prod.yaml`) similar to INT, this releases to PROD environment. It contains an additional check to ensure this only runs on a `release/*` branch. Plus, it has more granular steps for the traffic switchover in Front Door.

- **Azure.AlwaysOn E2E Release** (`azure-release-e2e.yaml`) implements an End-to-End deployment validation pipeline that contains the whole process of deploying infrastructure, build and push container images, build UI app, deploy the workload via Helm, conduct smoke tests and destroy the infrastructure at the end. This is the same pipeline used for INT and PROD, just with slightly different parameter settings to implement the complete removal of all deployed resources in the end. This pipeline is used for Pull Request validation and can also be used to spin up individual test and development environments.

Additionally there are some auxiliary pipelines:

- **Azure.AlwaysOn Deploy Locust (Standalone)** (`azure-deploy-locust.yaml`) deploys a standalone Locust-based load testing infrastructure using Terraform and Azure Container Instances. The environment can be scaled out by setting the number of worker nodes to >=1 or scaled down by setting the number to 0. The `terraform apply` task returns the FQDN of the load testing web interface. The web interface is protected with basic authentication, the required credentials to access the web interface are stored in Azure Key Vault. Check out the [Locust](/src/testing/loadtest-locust/README.md) specific documentation for more.

- **Azure.AlwaysOn Deploy Azure Load Generator.** (`azure-deploy-loadgenerator.yaml`) deploys a standalone Azure Functions-based load generator for simulating user activity. See the article on the [load generator](/src/testing/userload-generator/README.md) for more information.

All pipelines are defined in YAML and are stored in the Azure Mission-Critical online reference implementation GitHub repository in the `.ado/pipelines` directory:

 ![img](/docs/media/devops1.png)

All pipelines are using templates (stored in the `.ado/pipelines/templates` directory) – following the principle to write all logic only once as a template and use it in all/multiple pipelines. The pipeline definition itself should, whenever possible, contain only the pipeline structure and the code to load templates with different parameters.

As the highest level of reuse, the pipelines for INT, PROD and E2E release all use the same stage-template (`templates/stages-full-release.yaml`) and only define different input parameters for this template. That stage template in turn references various job- and steps-templates.

![img](/docs/media/devops3.png)

## Pipeline stages and jobs

Here is an example pipeline run for a release to INT:

![pipeline part 1](/docs/media/devops_zerodowntime_pipeline_1.png)
![pipeline part 2](/docs/media/devops_zerodowntime_pipeline_2.png)

You can see the different stages, their dependencies between each other and the jobs which are executed as part of each stage.

In summary, the following tasks are currently automated via pipelines:

- Deploy/update globally shared infrastructure
- Deploy release unit infrastructure
- Build Container Images and UI app
- Configure AKS clusters
- Deploy the container workloads to AKS and the UI app to static storage
- Smoke-test the API and the UI
- (Gradually) reconfigure Front Door to direct traffic to the newly deployed stamps
- Remove the previous release unit (plus the global infrastructure in case of the E2E pipeline)

All pipelines use pipeline artifacts to share information like FQDNs, Resource IDs etc. between stages. This is needed as the deployment of the infrastructure is dynamic and can create a varying number of regional deployments (stamps). For example, the output of the two Terraform deployment tasks (global resources and release unit resources) are stored as JSON files as artifacts. Similarly, the container image names are stored as artifacts to transfer the exact image name and tag from the build stage to the deployment stage.

![Artifacts](/docs/media/devops_pipeline_artifacts.png)

## Configuration files

All pipelines use a shared configuration(.yaml) stored in `.ado/pipelines/config`. This file is used as a central place to store and change configuration settings and version numbers.

```YAML
# Central configuration and versioning settings
# used for all pipelines
variables:
- name:  'helmVersion'         # helm package manager version
  value: 'v3.5.4'
```

In addition to the central configuration(.yaml) file as part of the repo, there are *environment-specific configuration files*.

Environment config files are stored in `.ado/pipelines/config` and are named `variables-values-[env].yaml`.

| Key | Description | Sample value |
| --- | --- | --- |
| prefix | Custom prefix used for Azure resources. **Must not be longer than 6 characters!** | int: myint, prod: myprod, e2e: mye2e |
| stampLocations | List of locations (Azure Regions) where this environment will be deployed into  | ["northeurope", "eastus2"] |
| terraformResourceGroup | Resource Group where the Terraform state Storage account will be deployed | terraformstate-rg |
| envDnsZoneRG | OPTIONAL: Name of the Azure Resource group which holds the Azure DNS Zone for your custom domain. Not required if you do not plan to use a custom DNS name | mydns-rg |
| envDomainName | OPTIONAL: Name of the Azure DNS Zone. Not required if you do not plan to use a custom DNS name | example.com |
| contactEmail | E-mail alias used for alerting. **Be careful which address you put in here as it will potentially receive a lot of notification emails** | alwaysonappnet@example.com |

## Service Connections

All pipelines are using Azure DevOps service connections to connect to Microsoft Azure. Access to these service connections is limited and needs to be granted on a per-pipeline level.

> There are **no** further service connections defined to connect directly to services like Kubernetes, Azure Container Registry or others. These services are accessed inline via Azure credentials.

* **alwayson-int-serviceconnection** is used to access the Azure subscription used for the integration (int) environment.
* **alwayson-prod-serviceconnection** is used to access the Azure subscription used for the production (prod) environment.
* **alwayson-e2e-serviceconnection**  is used to access the Azure subscription used for the end-to-end deployment tests.

## Smoke Testing

As part of the pipelines, basic Smoke Tests against the APIs are executed:

- GET call to the HealthService `/healthservice/health/stamp` API. Expected result: HTTP 200
- GET call the CatalogService `/catalogservice/api/1.0/catalogitem` API to retrieve a list of existing items. Expected result: HTTP 200
- POST call to the CatalogService `/catalogservice/api/1.0/catalogitem/{itemId}/comments` API to create a new comment for an existing item. Expected result: HTTP 202
- GET call to the CatalogService `/catalogservice/api/1.0/catalogitem/{itemId}/comments/{commentId}` API to retrieve the previously created comment. Expected result: HTTP 200

The calls are first executed against the individual stamps to test the availability of each regional deployment and afterwards against the global Front Door endpoint, which distributes the requests to the different stamps.

Additionally, two UI smoke tests are performed:

1. GET request to each of the stamp's Static Storage Web endpoint and Front Door endpoint, which then validates that the website contains the HTML page title "AlwaysOn Catalog". Since PowerShell doesn't run JavaScript on the site, this serves as a simple check if the HTML page was deployed to the storage account and is available.
1. UI test with [Playwright](/src/testing/ui-test-playwright/README.md) against the Front Door endpoint, which takes a screenshot of the home page and the catalog page and publishes them as pipeline artifacts. Playwright uses actual web browser engine (Chromium in our case), so it's possible to navigate in the app and "see" how it really looks like.

## Scripting

Some pipeline tasks execute scripts, whether inline or in separate script files. Scripts are written in cross-platform PowerShell, so that both Linux and Windows build agents can be used as required by workload deployments.

---

[Back to documentation root](/docs/README.md)
