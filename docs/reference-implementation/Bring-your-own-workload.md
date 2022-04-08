# Bring your own workload

The Azure Mission-Critical reference implementation follows a mono-repo approach hosting workload, infrastructure and supporting artifacts in the same repository. This is mainly done to make the reuse and maintenance as easy as possible. In a real-world environment (see [Brownfield considerations](./Brownfield-Considerations.md)) this can be different and the application code is often times separated from the infrastructure. In this guide we will describe the most common approaches to get existing workloads into the Azure Mission-Critical deployment.

## Mono-repo

The easiest way to implement existing workloads is to continue with the mono-repo approach. New workloads can be added to the repo and the pipelines extended to build, push and deploy it to the infrastructure.

### Application Code

The application code is stored in the `/src/app/` directory. Each application has its own directory and contains a `Dockerfile` which is used to build the container image.

```bash
src/app/
├── <application>
│   ├── Dockerfile
```

This `Dockerfile` is picked up by the `Build Application Code` stage of the pipeline. This pipeline can be easily extended to build and push additional images to the Azure Container Registry.

```yaml
  - template: jobs-container-build.yaml
    parameters:
      jobName: '<app-name>' # unique pipeline job name
      containerImageName: '<container-image-name>' # container image name
      containerImageDockerFile: '<dockerfile>' # dockerfile used to build the container image
```

The `jobs-container-build.yaml` template expects the files to be stored in `/src/app`. This can be overrided by the `workingDirectory` parameter if needed.

## Multi-repo

In a multi-repo environment, the application code is stored in a different or in individual repositories, separated from the infrastructure. This also means that the application code is usually build and pushed in a separate pipeline.

The main consideration here is to which registry the container images are pushed (e.g. to a corp-wide central container registry (see [Brownfield considerations](./Brownfield-Considerations.md))) and how they can be accessed and pulled to the clusters we're deploying here.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
