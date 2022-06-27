# Brownfield scenario considerations

While the initial usage of the Azure Mission-Critical reference implementation often times include deploying it into empty Azure subscription(s) aka greenfields, is it not limited to that. This guide describes some of the most common scenarios when deploying the Azure Mission-Critical reference implementation into existing environments aka brownfield scenarios.

## Existing networking infrastructure

The Azure Mission-Critical online reference implementation maintains its own virtual networks and subnets. It is supposed to be deployed fully independent of any existing infrastructure. For environments with existing networking infrastructure or requirements for connectivity to existing services either on-premises or in another virtual network, it is required to use the [Azure Mission-Critical - Connected](https://github.com/Azure/Mission-Critical-Connected/) reference implementation.

## Existing container registry

All Azure Mission-Critical reference implementations contain dedicated Azure Container Registries per environment. They are deployed as part of the global services and replicated to each of the regional deployment stamp locations, to host container images built and pushed as part of the overall deployment pipelines. The lifecycle of this ACR instances are different depending on the environment typ. This is done to keep the external dependencies of a deployment as minimal as possible and it also allows us to deploy the whole solution end-to-end as part of the E2E deployment pipeline.

In brownfield environments it is often times considered to use an already existing central container registry for some or all container images. This is **not recommended**. You can still use a centrally managed container registry to store container images, and import them from there into the per-environment container registry in Azure Mission-Critical.

Reasons to use the per environment container registries are:

- The blast radius of an outage of the container registry is limited to a single environment.
- The container registry can be integrated with AKS (or other compute services) to reduce the need for individual credentials.
  > Azure Container Registries provide only a limited set of functionality to restrict access in multi-tenant scenarios.
- The container registry can be restricted to a given solution using Private Endpoints.
- The container registry can be replicated to the same locations where the solution is deployed.

> **Important!** According to the Azure Mission-Critical design guidance, our clear recommendation is to use dedicated Azure Container Registries. Container images that exist in another container registry should either be pushed or imported into the solution's container registry.

## Existing workload

When a deployment of the Azure Mission-Critical reference implementation evolves towards a more production-ready environment, the sample application needs to be replaced with the real workload. The online reference implementation comes with a sample workload that can be used as a starting point for a real workload. It follows our best practices to build, push and deploy a workload.

The [Bring your own workload](./Bring-your-own-workload.md) section describes the process to replace the sample workload with a real workload.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
