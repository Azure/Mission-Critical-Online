# Brownfield scenario considerations

While the initial usage of the Azure Mission-Critical reference implementation often times include deploying it into empty Azure subscription(s) aka greenfields, is it not limited to that. This guide describes some of the most common scenarios when deploying the Azure Mission-Critical reference implementation into existing environments aka brownfield scenarios.

## Existing networking infrastructure

The Azure Mission-Critical online reference implementation comes with its own virtual network and subnets. It is supposed to be deployed fully independent of any existing infrastructure. For environments with existing networking infrastructure or requirements for connectivity to existing services either on-premises or in another virtual network it is recommended to use the [Azure Mission-Critical - Connected](https://github.com/Azure/Mission-Critical-Connected/) reference implementation.

## Existing container registry

All Azure Mission-Critical reference implementations come with its on Azure Container Registry, deployed as part of the global services and replicated to each of the regional deployment stamp locations, to host container images (for the sample catalog workload) build and pushed as part of the overall deployment pipelines. This is done to keep the external dependencies of a deployment as minimal as possible and it also allows us to deploy the whole solution end-to-end as part of the E2E deployment pipeline.

In brownfield environments it is often times considered to use an already existing central container registry for some or all container images. When a central container registry is used following considerations should be taken into account:

* The container registry should be configured to replicate the images to the regional deployment stamp locations. The availability and performance of the registry can limit the overall deployments availability.
* The compute platform used to host containers (AKS, AppSvc, ..) needs to be configured to use the container registry and allows pulling images. Otherwise `ImagePullSecrets` need to be specified.
* The build/push process for container images is currently embedded into the deployment pipelines. This can be changed and separated into individual pipelines. The deployment pipeline then needs to refer to the container registry hosting the images and pointing to the right image version (using `latest` is not recommended).
* Helm charts are currently applied from the git repository. These charts can also be pushed to a container registry and pulled from there.

Reasons for a dedicated container registries per solution are:

* The blast radius of an outage of the container registry is limited to a single solution.
* The container registry can be integrated with AKS (or other compute services) to reduce the need for individual credentials. On top of that provides Azure Container registry only a limited set of functionality to restrict access in multi-tenant scenarios.
* The container registry can be restricted to a given solution using Private Endpoints.
* The container registry can be replicated to the same locations where the solution is deployed.

> **Important!** According to the Azure Mission-Critical design guidance, our clear recommendation is to use dedicated Azure Container Registries.

## Existing workload

When the Proof-of-Concept deployment of the Azure Mission-Critical reference implementation evolves towards a more production-ready environment the next ask is to replace the sample application with a real workload. The online reference implementation comes with a sample workload that can be used as a starting point for a real workload. It follows our best practices to build, push and deploy a workload.

The [Bring your own workload](./Bring-your-own-Workload.md) guide describes the process to replace the sample workload with a real workload.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
