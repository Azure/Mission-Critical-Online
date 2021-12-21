# TODO!

- Substitute Chaos Studio public documentation links below for internal https://pppdocs.azurewebsites.net/ChaosEngineering/* docs
- Add info about AlwaysOn AzDO pipeline incorporation of Chaos Experiment deploy/run and Chaos Mesh install on deployed AKS clusters

# Chaos Engineering and Testing

Large-scale distributed applications consist of multiple infrastructure and application components and services. Resilient applications need to be hardened against and designed to gracefully handle disruptions and failures to system components, infrastructure, and dependencies. Resilience is thus a property of the entire distributed application and which needs to be validated in an integrated environment with conditions and load similar to production.

Chaos Engineering is the practice of subjecting applications and services to real-world stresses and failures by injecting faults that introduce errors. Azure Chaos Studio is the Azure native Chaos Engineering platform, supporting different Azure resource types and specific fault types that can be injected to disrupt each of the supported Azure resource types.

## Azure Chaos Studio

Azure Chaos Studio is the Azure native Chaos Engineering platform. Chaos Studio provides the following entities:

- Chaos Experiment: a set of one or more Faults that are executed in parallel or sequentially. A Chaos Experiment is an Azure resource which is deployed into a Resource Group. A Chaos Experiment is the runnable artifact which will execute the Fault injections defined in the Experiment.
- Step: the Experiment work unit. If an Experiment contains multiple Steps, the Steps will run in series (i.e. one after the other).
- Branch: each Step contains one or more Branches. If a Step contains more than one Branch, the Branches will run in parallel (i.e. at the same time).
- Fault: each Branch contains a specific Fault to inject, and specifies the Azure resource targets to disrupt with the Fault.
- Selector: a list of one or more Azure resources to target. This is provided in the Branch, so the Fault can be targeted at the resource(s) specified in the Selector.

![Azure Chaos Studio Entities](/docs/media/Chaos-Experiment.png "Azure Chaos Studio Entities")

## Azure Chaos Studio Fault Types

Azure Chaos Studio supports two types of Faults: service-direct and agent-based.

Service-direct Faults are injected directly onto the Azure control plane. Agent-based Faults are injected by an agent running in the guest operating system of a Virtual Machine (VM) or Virtual Machine Scale Set (VMSS).

## Azure Chaos Providers and Configurations

Chaos Experiments target Azure resources within a subscription. Before running any Chaos Experiments, the subscription must be configured with an Azure Chaos Provider Configuration corresponding to the targeted resource type(s).

Currently available Chaos Provider Configurations and corresponding targeted Azure resource types (as of September 2021):

| Chaos Provider Configuration | Azure Resource Type | Fault Type |
| --- | --- | --- |
| `AzureVmChaos` | `Microsoft.Compute/virtualMachines` | Service-direct |
| `AzureVmssVmChaos` | `Microsoft.Compute/virtualMachineScaleSets` | Service-direct |
| `AzureCosmosDbChaos` | `Microsoft.DocumentDb/databaseAccounts` | Service-direct |
| `ChaosMeshAKSChaos` | `Microsoft.ContainerService/managedClusters` | Service-direct |
| `AzureNetworkSecurityGroupChaos` | `Microsoft.Network/networkSecurityGroup` | Service-direct |
| `ChaosAgent` | `Microsoft.Compute/virtualMachines`<br />`Microsoft.Compute/virtualMachineScaleSets` | Agent-based |

More Chaos Provider Configurations and corresponding Azure resource types will be added in the future.

In order to target a specific supported Azure resource type with one or more Chaos Experiments, the Azure subscription containing the targeted resource(s) must first be configured to support the corresponding Chaos Provider Configuration. This is a one-time configuration per subscription.

For example, if multiple Azure Cosmos DB instances in an Azure subscription will be targeted over time, the `AzureCosmosDbChaos` Chaos Provider Configuration will only need to be configured once on that subscription.

## Chaos Experiment Managed Identity

Each Chaos Experiment that is created is associated with a System Managed Identity that is created with the Chaos Experiment (In the future, re-using User Managed Identities will be supported.)

After a Chaos Experiment with Service-direct Faults is created, appropriate Role Assignments for its Managed Identity will also need to be created so that the Experiment Managed Identity can inject Faults into the targeted resource(s). Chaos Experiments that only contain Agent-based Faults do not need an Experiment Managed Identity Role Assignment.

For example, if a `ChaosMeshAKSChaos` Experiment is created, an RBAC Role Assignment must be created permitting the Experiment Identity to operate on the targeted AKS Cluster(s). The Role Assignment's scope can be the specific targeted resource(s), or the Resource Group(s) containing the targeted resources, which will inherit the permissions granted by the Role Assignment.

Each Chaos Provider Configuration has a recommended RBAC role that should be assigned to the Experiment Managed Identity so that Experiments can execute against the targeted resource type.

| Chaos Provider Configuration | Suggested Role Assignment |
| --- | --- |
| `AzureVmChaos` | Virtual Machine Contributor |
| `AzureVmssVmChaos` | Virtual Machine Contributor |
| `AzureCosmosDbChaos` | Cosmos DB Operator |
| `ChaosMeshAKSChaos` | Azure Kubernetes Service Cluster User Role |
| `AzureNetworkSecurityGroupChaos` | Network Contributor |

The following example shows how to retrieve the Managed Identity created with a Chaos Experiment and then create an RBAC Role Assignment for it. The scope in this example is the Resource Group containing the targeted resource(s), but this example can be modified to make the Role Assignment scope more specific to just the targeted resource instead of the Resource Group.

```bash
subscriptionId="$(az account show -o tsv --query 'id')" # Get the default subscription ID
experimentResourceGroup="ExperimentResourceGroup" # Substitute correct Resource Group name where Chaos Experiments will be deployed
experimentName="ChaosExperiment" # Substitute a meaningful Experiment name
targetResourceGroup="TargetResourceGroup" # Substitute correct Resource Group name where targeted resource(s) are deployed
rbacRoleName="Cosmos DB Operator" # Substitute the correct RBAC role name from the above table
apiVersion="2021-06-21-preview"

# Get Target Resource Group ID
targetRGResourceId="$(az group show --name ""$targetResourceGroup"" -o tsv --query 'id')"

# Get Experiment Managed Identity Principal ID
url="https://management.azure.com/subscriptions/""$subscriptionId""/resourceGroups/""$experimentResourceGroup""/providers/Microsoft.Chaos/chaosExperiments/""$experimentName""?api-version=""$apiVersion"
experimentPrincipalId="$(az rest --method get --url ""$url"" -o tsv --query 'identity.principalId')"

# Create Role Assignment for Experiment Managed Identity
az role assignment create --role "$rbacRoleName" --scope "$targetRGResourceId" --assignee-object-id "$experimentPrincipalId" --assignee-principal-type "ServicePrincipal" --verbose
```

## Chaos Experiment Fault Types

The `ChaosMeshAKSChaos`, `AzureCosmosDbChaos`, and `AzureNetworkSecurityGroupChaos` Chaos Providers correspond to Azure resource types used by AlwaysOn: Azure Kubernetes Service (AKS), Cosmos DB, and Network Security Groups.

Each of these Chaos Providers has Fault types which are used in Experiments targeting the corresponding AlwaysOn Azure resource types. Additional Fault types will be added to Azure Chaos Studio in the future.

| Chaos Provider Configuration | Fault | Description |
| --- | --- | --- |
| `AzureCosmosDbChaos` | Cosmos DB Failover | Causes a Cosmos DB account with a single write region to fail over to a specified read region in order to simulate a write region outage.<br /><br />(Note that AlwaysOn uses multiple write regions. This Fault type may still be useful to test unavailability of a stamp's in-region Cosmos DB replica.) |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh Network | Causes a network fault available through Chaos Mesh to run against the targeted AKS cluster.<br /><br />Useful for recreating AKS incidents resulting from network outages, delays, duplications, loss, and corruption. |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh Pod | Causes a pod fault available through Chaos Mesh to run against the targeted AKS cluster.<br /><br />Useful for recreating AKS incidents that are a result of pod failures or container issues. |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh Stress | Causes a stress fault available through Chaos Mesh to run against the targeted AKS cluster.<br /><br />Useful for recreating AKS incidents due to stresses over a collection of pods, e.g. due to high CPU or memory consumption. |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh IO | Causes an IO fault available through Chaos Mesh to run against the targeted AKS cluster.<br /><br />Useful for recreating AKS incidents due to IO delays and read/write failures when using IO system calls such as `open`, `read`, and `write`. |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh Time | Causes a change in the system clock on the targeted AKS cluster using Chaos Mesh.<br /><br />Useful for recreating AKS incidents that result from distributed systems falling out of sync, missing/incorrect leap year/leap second logic, and more. |
| `ChaosMeshAKSChaos` | AKS Chaos Mesh Kernel | Causes a kernel fault available through Chaos Mesh to run against the targeted AKS cluster.<br /><br />Useful for recreating AKS incidents due to Linux kernel-level errors such as a mount failing or memory not being allocated. |
| `AzureNetworkSecurityGroupChaos` | Network Security Group (Set Rules) | Enables manipulation or creation of a rule in existing Network Security Group(s).<br /><br />Useful for simulating an outage of a downstream or cross-region dependency/non-dependency, simulating an event that is expected to trigger a logic to force a service failover, simulating an event that is expected to trigger an action from a monitoring or state management service, or as an alternative for blocking, or allowing, network traffic where Chaos Agent can not be deployed. |

## Subscription Onboarding

### Resource Provider Registration

To deploy and run Azure Chaos Studio Experiments in an Azure subscription, the Microsoft.Chaos Resource Provider must be registered on the subscription.

The AlwaysOn deployment pipelines include this step for targeted subscriptions. This can also be done manually for other subscriptions.

```bash
subscriptionId="$(az account show -o tsv --query 'id')" # Get the default subscription ID
apiVersion="2019-10-01"

az rest --method post --url "https://management.azure.com/subscriptions/""$subscriptionId""/providers/Microsoft.Chaos/register?api-version=""$apiVersion"
```

Resource Provider registration can take a few minutes until reaching "Registered" status, and can be checked as follows.

```bash
subscriptionId="$(az account show -o tsv --query 'id')" # Get the default subscription ID

az provider list --subscription $subscriptionId --query "sort_by([?namespace=='Microsoft.Chaos'&&registrationState=='Registered'].{Provider:namespace, Status:registrationState}, &Provider)" --out table

Provider         Status
---------------  ----------
Microsoft.Chaos  Registered
```

### Chaos Provider Configuration

To run Chaos Experiments targeting a specific Azure resource type, the corresponding Chaos Provider Configuration must first be registered on the subscription, as described above. Following is an example of registering the `AzureCosmosDbChaos` Chaos Provider Configuration.

```bash
subscriptionId="$(az account show -o tsv --query 'id')" # Get the default subscription ID
chaosProviderType="AzureCosmosDbChaos"
apiVersion="2021-06-21-preview"

url="https://management.azure.com/subscriptions/""$subscriptionId""/providers/Microsoft.Chaos/chaosProviderConfigurations/""$chaosProviderType""?api-version=""$apiVersion"

chaosProviderConfig="
{
  \"properties\": {
    \"enabled\": true,
    \"providerConfiguration\": {
      \"type\": \"""$chaosProviderType""\"
    }
  }
}"

az rest --method put --url "$url" --body "$chaosProviderConfig"
```

The above example uses the Azure Management REST API. Support for Chaos Provider Configuration registration and other Chaos Studio management operations will also be available in the Azure Command Line Interface (CLI), PowerShell, ARM templates, and Azure Portal.

## Chaos Experiments

AlwaysOn includes several Chaos Experiments targeting the Azure Kubernetes Service (AKS), Cosmos DB, and Network Security Groups used by AlwaysOn with the corresponding `ChaosMeshAKSChaos`, `AzureCosmosDbChaos`, and `AzureNetworkSecurityGroupChaos` Chaos Studio Fault Providers.

To create additional Chaos Studio Experiments, please consult the [Chaos Studio Documentation](https://aka.ms/chaosstudio "Chaos Studio Documentation").

### Chaos Experiments on non-AKS Resources

To create additional Service-direct Fault Chaos Experiments on Azure resource types other than AKS, follow the [Chaos Studio documentation](https://pppdocs.azurewebsites.net/ChaosEngineering/Onboarding/create_experiment_service_direct_fault.html "Chaos Studio documentation for creating Service-direct Fault Chaos Experiments").

### Chaos Experiments on AKS

Chaos Experiments targeting AKS require additional steps than Experiments targeting other Azure resource types.

Chaos Experiments targeting AKS use Fault specifications derived from [Cloud Native Compute Foundation (CNCF) Chaos Mesh](https://chaos-mesh.org/docs/ "Chaos Mesh Documentation"). To target AKS cluster(s) with Chaos Experiments, Chaos Mesh must first be installed on the targeted AKS cluster(s).

The AlwaysOn deployment pipelines include Chaos Mesh installation for deployed AKS cluster(s). For other/existing AKS clusters, Chaos Mesh can also be manually installed. Two installation methods are available: [via Helm chart](https://chaos-mesh.org/docs/production-installation-using-helm "Chaos Mesh Installation via Helm Chart") or [offline](https://chaos-mesh.org/docs/offline-installation "Chaos Mesh Offline Installation").

Sample Chaos Mesh Fault Specification files are available from [Chaos Mesh](https://github.com/chaos-mesh/chaos-mesh/tree/master/examples "Chaos Mesh Github Repository with Chaos Mesh YAML Fault Specification Examples").

Note that Chaos Mesh YAML Fault Specifications must be translated to Chaos Studio JSON format. The `-spec` node must be extracted and reformatted as JSON. This can be done using the `yq` tool.

```bash
# Install YQ locally to read YAML and convert JSON
# For GH pipeline: https://mikefarah.gitbook.io/yq/usage/github-action
# https://mikefarah.gitbook.io/yq/
# EXAMPLE USAGE: yq eval '.spec' dns-chaos.error.yaml --tojson --indent 0 > dns-chaos.error.json
YQVERSION=v4.12.1 # See releases at https://github.com/mikefarah/yq/releases
YQBINARY=yq_linux_amd64
sudo wget https://github.com/mikefarah/yq/releases/download/${YQVERSION}/${YQBINARY} -O /usr/bin/yq && sudo chmod +x /usr/bin/yq

# Paths for YAML input file (Chaos Mesh Fault Spec) and JSON output file (Chaos Studio Fault Spec)
inputPath="./fault.yaml"
outputPath="./fault.json"

# Transform YAML to minified JSON. Take only the -spec node.
experimentJson="$(yq eval '.spec' ""$inputPath"" --tojson --indent 0)"

# Write the JSON to output file
echo $experimentJson > $outputPath
```

To create a Chaos Experiment using the JSON fault spec created above, the JSON must be sent to the Azure Management REST API in an HTTP PUT as the body payload. Note that depending on which HTTP utility is used, the JSON may need to be escaped. The following example uses `az rest`, which automatically escapes body payloads.

```bash
subscriptionId="$(az account show -o tsv --query 'id')" # Get the default subscription ID
experimentResourceGroup="ExperimentResourceGroup" # Substitute correct Resource Group name where Chaos Experiments will be deployed
experimentName="ChaosExperiment" # Substitute a meaningful Experiment name
apiVersion="2021-06-21-preview"

url="https://management.azure.com/subscriptions/""$subscriptionId""/resourceGroups/""$experimentResourceGroup""/providers/Microsoft.Chaos/chaosExperiments/""$experimentName""?api-version=""$apiVersion"

az rest --method put --url "$url" --body "$experimentJson"
```

As with other Chaos Experiment script examples shown here, support for Azure CLI, PowerShell, ARM template, and Azure Portal will also be provided to create and run Chaos Experiments.

### Running and Managing Experiments

Once Chaos Experiments are created, they can be run and managed.

AlwaysOn end to end pipelines include Chaos Experiment runs. Chaos Experiments can also be run manually or programmatically outside of AlwaysOn pipelines. Consult the [Chaos Studio documentation](https://pppdocs.azurewebsites.net/ChaosEngineering/Onboarding/execute_experiment.html "Chaos Studio documentation for running and managing Chaos Experiments") for details.

## AlwaysOn Pipelines

The following AlwaysOn Azure DevOps pipelines include Chaos Studio support.

### End to End

The [azure-release-e2e.yaml](/.ado/pipelines/azure-release-e2e.yaml) pipeline includes optional support for the following steps.

1. Deploy CNCF Chaos Mesh to the deployed stamp AKS cluster(s)
2. Create Chaos Experiments targeting global and stamp resources
3. Create appropriate RBAC Role Assignments for the Chaos Experiment Managed Identities
4. Orchestrate a Load Test - Steady State - Chaos Experiment process to load-test the deployment first without, then with Chaos Experiments running to validate deployment resiliency and performance.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)