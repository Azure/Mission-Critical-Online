# Sample Application

The Azure Mission-Critical online reference implementation uses a simple web shop catalog application where end users can browse through a catalog of items, see details of an item, and post ratings and comments for items. Although fairly straight forward, this application enables the [Reference Implementation](/docs/reference-implementation/README.md) to demonstrate the asynchronous processing of requests and how to achieve high throughput within a solution. The application consists of three components and is implemented in .NET Core and hosted on Azure Kubernetes Service.

See [Application Design](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-app-design) for more details about the application.

## Code

The application code for each component is stored in individual directories in the `/src/app` directory:

* [AlwaysOn.CatalogService implementation](/src/app/AlwaysOn.CatalogService/README.md)
* [AlwaysOn.BackgroundProcessor implementation](/src/app/AlwaysOn.BackgroundProcessor/README.md)
* [AlwaysOn.HealthService implementation](/src/app/AlwaysOn.HealthService/README.md)
* [AlwaysOn.UI implementation](/src/app/AlwaysOn.UI/README.md)

## Containers

Each application component has its individual Dockerfile. These Dockerfiles are used to build & push container images to our Azure Container Registry.

## HTML UI

Demo user interface is implemented as HTML & JavaScript website, and although it has its own Dockerfile (for local debugging), it's hosted on a Storage Account, instead of being deployed as a container to AKS.

The UI is compiled in the CI pipeline and uploaded to Azure Storage accounts in the CD pipeline. Each stamp hosts a storage account for hosting the UI. These Storage Accounts are enabled for [Static Website hosting](https://docs.microsoft.com/azure/storage/blobs/storage-blob-static-website) and are added as backends in Azure Front Door. The routing rule for the UI is configured with aggressive caching so that the content, even though very small, rarely needs to be loaded from storage and is otherwise directly served from Azure Front Door's edge nodes.

## Helm Charts

The `/src/app/charts` directory contains individual Helm charts for each of the application components like CatalogService, BackgroundProcessor and HealthService. Helm is used to package the YAML manifests needed to deploy the individual components together including their deployment, services as well as the auto-scaling (HPA) configuration. Each Helm chart contains a `values.yaml` file that contains default values and is used as an argument reference.

These workload Helm charts used in Azure Mission-Critical are currently not uploaded into a Helm registry, they're applied directly via Helm via an Azure DevOps pipeline from within the repository.

### Security Context

All Helm charts contain foundational security measures following K8s best practices. These security measures are:

* `readOnlyFilesystem` The root filesystem `/` in each container is set to read-only. This is to prevent the container from accidentally writing to the host filesystem. Directories that require read-write access are mounted as volumes.
* `privileged` All containers are set to run as **non-privileged**. Running a container as privileged gives all capabilities to the container, and it also lifts all the limitations enforced by the device cgroup controller.
* `allowPrivilegeEscalation` Prevents inside of a container to gain more privileges than its parent process.

These security measures are also configured for 3rd-party containers and helm charts (i.e. cert-manager) when possible and audited by Azure Policy.

### Network Policy

Each of our workload Helm charts contains foundational Network Policies. These policies are enabled by default and can be disabled per chart via `.Values.networkpolicy.enabled`. The `CatalogService` contains a `default-deny` rule that denies all traffic in the `workload` namespace, that is not explicitly allowed. See the individual workload readme for more details.

---

[Back to documentation root](/docs/README.md)
