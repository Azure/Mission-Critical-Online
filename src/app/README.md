# Sample Application

The AlwaysOn demo application represents a simple game of [Rock-Paper-Scissors-Lizard-Spock](http://www.samkass.com/theories/RPSSL.html). The application consists of three components and is implemented in .NET Core and hosted on Azure Kubernetes Service.

See [Application Design](/docs/reference-implementation/AppDesign-Application-Design.md) for more details about the application.

## Code

The application code for each component is stored in individual directories in the `/src/app` directory:

* [AlwaysOn.GameService implementation](/src/app/AlwaysOn.GameService/README.md)
* [AlwaysOn.ResultWorker implementation](/src/app/AlwaysOn.ResultWorker/README.md)
* [AlwaysOn.HealthService implementation](/src/app/AlwaysOn.HealthService/README.md)
* [AlwaysOn.UI implementation](/src/app/AlwaysOn.UI/README.md)

## Containers

Each application component has its individual Dockerfile. These Dockerfiles are used to build & push container images to our Azure Container Registry.

## HTML UI

Demo user interface is implemented as HTML & JavaScript website, and although it has its own Dockerfile (for local debugging), it's hosted on a Storage Account, instead of being deployed as a container to AKS.

The UI is compiled in the CI pipeline and uploaded to Azure Storage accounts in the CD pipeline. Each stamp hosts a storage account for hosting the UI. These Storage Accounts are enabled for [Static Website hosting](https://docs.microsoft.com/azure/storage/blobs/storage-blob-static-website) and are added as backends in Azure Front Door. The routing rule for the UI is configured with aggressive caching so that the content, even though very small, rarely needs to be loaded from storage and is otherwise directly served from Azure Front Door's edge nodes.

## Helm Charts

The `/src/app/charts` directory contains individual Helm charts for each of the application components like GameService, ResultWorker and HealthService. Helm is used to package the YAML manifests needed to deploy the individual components together including their deployment, services as well as the auto-scaling (HPA) configuration.

These Helm charts are currently not uploaded into a Helm registry, they're applied directly via Helm via an [Azure DevOps pipeline](/docs/reference-implementation\DeployAndTest-DevOps-Design-Decisions.md) from within the repository.

---

[Back to documentation root](/docs/README.md)
