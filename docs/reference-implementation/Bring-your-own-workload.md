# Bring your own workload

The Azure Mission-Critical reference implementation follows a mono-repo approach hosting workload, infrastructure and supporting artifacts in the same repository. This is mainly done to make the reuse and maintenance as easy as possible. In a real-world environment (see [Brownfield considerations](./Brownfield-Considerations.md)) this can be different and the application code is often times separated from the infrastructure. In this guide we will describe the most common approaches to get existing workloads into the Azure Mission-Critical deployment.

* [Application Code](#application-code)
* [Kubernetes](#kubernetes)

## Application Code

The easiest way to implement existing workloads is to continue with the **mono-repo** approach. New workloads including their sourcecode can be added to the repo, and the existing pipelines can be extended to build, push and deploy it to the infrastructure.

In a **multi-repo** environment, the application code is stored in a different or in individual repositories, separated from the infrastructure. This also means that the application code is usually build and pushed in a separate pipeline.

The following two sub-sections contain information on how to either bring workloads via the mono-repo approach or via the multi-repo approach into the Azure Mission-Critical environment.

### Mono-repo

The application code is stored in the `/src/app/` directory. Each application has its own directory and contains a `Dockerfile` which is used to build the container image.

```bash
src/app/
├── <application1>
│   ├── Dockerfile
│   ├── ...
├── <application2>
│   ├── ...
```

This `Dockerfile` is picked up by the `Build Application Code` stage of the pipeline. This pipeline can be easily extended to build and push additional images to the Azure Container Registry. The process itself is baked into a template that requires only three parameters:

```yaml
  - template: jobs-container-build.yaml
    parameters:
      jobName: '<app-name>' # unique pipeline job name
      containerImageName: '<container-image-name>' # container image name
      containerImageDockerFile: '<dockerfile>' # dockerfile used to build the container image
```

The `jobs-container-build.yaml` template expects the files to be stored in `/src/app/`. The `containerImageDockerFile` parameter specifies the relative path from there to the `Dockerfile` i.e. `application1\Dockerfile`. This can be overridden by the `workingDirectory` parameter if needed.

### Multi-repo

The main consideration here is to which registry the container images are pushed (e.g. to a corp-wide central container registry (see [Brownfield considerations](./Brownfield-Considerations.md)) and how they can be accessed and pulled to the clusters we're deploying here.

## Kubernetes

Assuming that we have our container images build and pushed to a container registry, the next step is to deploy the workload to each of our Kubernetes clusters in each of the region deployment stamps.

The Azure Mission-Critical reference implementation uses Helm to package Kubernetes manifests and deploy them. The application-specific Helm charts are stored in `/src/app/charts`. These charts are not pushed to a container registry, they're applied directly from the repository as part of the deployment pipeline.

Depending on the type of environment, using the [mono-repo](#mono-repo) or [multi-repo](#multi-repo) approach, these Helm charts might existing outside of the infrastructure repository as well either in another repo or pushed to a container registry.

To deploy them into the Azure Mission-Critical environment, the `jobs-workload-deploy.yaml` template that contains individual tasks to deploy workloads to the clusters, needs to be extended.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
