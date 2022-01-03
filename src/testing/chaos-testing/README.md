# Chaos Experiments

The reference implementation of AlwaysOn integrates Azure Chaos Studio (currently in preview) to inject faults by creating and executing Chaos experiments.

Chaos experiments can be executed as an optional part of the E2E deployment pipeline. In case they are executed, the optional load test is always executed in parallel as well. This is to create some load on the cluster to actually validate the impact of the injected faults.

## AKS fault injection - Chaos Mesh

To inject faults into the compute platform, [Chaos Mesh](https://chaos-mesh.org/) is being installed on the AKS clusters. Azure Chaos Studio in turn is using Chaos Mesh to run and control the experiments.

Currently three different experiments are configured as part of the pipeline to demonstrate the process:

- Pod Killer - randomly kills pods from the `workload` namespace. AKS should immediately reschedule those.
- Pod CPU stress - brings the CPU load on random pods from the `workload` namespace to 100 per cent.
- Pod Memory stress - increases the memory utilization on random pods from the `workload` namespace to 100 per cent.

The fault definitions for those can be found in the `./chaos-mesh` directory. More faults are available in the official [Chaos Mesh GitHub repository](https://github.com/chaos-mesh/chaos-mesh/tree/master/examples).

## E2E deployment pipeline integration

When a user selects the optional Chaos experiment execution as part of the E2E deployment pipeline, a couple of additional steps are added in the pipeline:

1) As part of the [AKS `Configuration` stage](.ado/pipelines/templates/jobs-configuration.yaml), Chaos Mesh components are installed on each of the clusters, using Helm.
1) The integrated Load Test is executed.
1) In parallel to the Load Test, the [Chaos stage](.ado/pipelines/templates/stages-chaos.yaml) is executed.

### Chaos stage

To enable fault injection on AKS clusters, they need to be enabled as Chaos "targets". This is done by creating child-resources of the clusters through a call to the Azure REST API, for example:
```
PUT https://management.azure.com/subscriptions/.../resourcegroups/.../providers/Microsoft.ContainerService/managedClusters/aoe2e122e-.../providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2021-08-11-preview
```

Next, certain Chaos Mesh "capabilities" need to be enabled in a similar fashion, e.g. to enable `PodChaos-1.0`:
```
PUT https://management.azure.com/subscriptions/.../resourcegroups/.../providers/Microsoft.ContainerService/managedClusters/aoe2e122e-.../providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/PodChaos-1.0?api-version=2021-08-11-preview
```

Together with the previous Chaos Mesh component installation, the cluster is now ready to be targeted by a Chaos Studio experiment.

For this, a Chaos experiment gets created which contains the resource IDs of the targets as well as the actual fault definition in the Chaos Mesh syntax (see above) - when targeting AKS - and other properties like experiment duration. The different JSON template files for the experiments are located in the [`./experiment-json/`](./experiment-json/) directory. The [pipeline script](/.ado/scripts/Invoke-ChaosMeshExperiment.ps1) fills in the placeholder resource IDs with the actual values, creates the experiment via the ARM REST API and then starts the experiment.

The script then polls the experiment status and waits for its completion.

The pipeline executes each configured experiment in sequence (currently: Pod Killer, CPU Stress and Memory Stress). All the while the load test is running against the workload.