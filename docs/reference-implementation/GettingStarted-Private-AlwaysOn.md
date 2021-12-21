# Getting started with AlwaysOn Private

This guide walks you through the required steps to switch from the default, public version of AlwaysOn to the private version. The private version locks down all traffic to the deployed Azure services to Private Endpoints only. Only the actual user traffic is still flowing in through the public ingress point of [Azure Front Door](https://azure.microsoft.com/services/frontdoor/#overview).

This deployment mode provides even tighter security but requires the use of self-hosted, VNet-integrated Build Agents. Also, for any debugging etc. users must connect through Azure Bastion and Jump Servers.

![AlwaysOn Private Mode Architecture](/docs/media/Architecture-Private.png)

## Overview

On a high level, the following steps will be executed:

1. Import Azure DevOps pipeline which deploys self-hosted Build Agents
1. Run the new pipeline to deploy the Virtual Machine Scale Sets for the Build Agents as well as Jump Servers and other supporting resources
1. Configure the self-hosted Build Agents in Azure DevOps
1. Change the deployment pipeline definitions to use the self-hosted Build Agents instead of the Microsoft-hosted Agents
1. Set required variables in the Terraform variables files to enable the private stamps and reference the self-hosted Build Agent resources to later be able to create Private Endpoints

## Import pipeline to deploys self-hosted Build Agents

To deploy the infrastructure for the self-hosted Agents and all supporting services such as Jump Servers and private DNS zones, a ready-to-use Terraform template plus the corresponding ADO Pipeline is included in this repository.

> The following steps assume that you have already followed the general [Getting Started guide](/docs/reference-implementation/Getting-Started.md). If you have not done so yet, please go there first.

1. The ADO pipeline definition resides together with the other pipelines in `/.ado/pipelines`. It is called `azure-deploy-private-build-agents.yaml`. Start by importing this pipeline in Azure DevOps.

    ```bash
    # set the org/project context
    az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

    # import a YAML pipeline
    az pipelines create --name "Azure.AlwaysOn Deploy Build Agents" --description "Azure.AlwaysOn Build Agents" \
                        --branch main --repository https://github.com/<your-fork>/ --repository-type github \
                        --skip-first-run true --yaml-path "/.ado/pipelines/azure-deploy-private-build-agents.yaml"
    ```

    > You'll find more information, including screenshots on how to import and manage YAML-based pipelines in the overall [Getting Started Guide](./Miscellaneous-Getting-Started.md).

1. Now locate the Terraform variables files for the Build Agent deployment at `/src/infra/build-agents/variables.tf`. Adjust the values as required for your use case. For instance, you might want to change the deployment location. If you (later) want to change the SKU size of the VMs for Build Agents and/or Jump Servers, those settings are maintained in the respective `vmss-*.tf` template files in the same directory.

1. If you already know that you have special requirements regarding the software that needs to be present on the Build Agents to build your application code, go modify the `cloudinit.conf` in the same directory.

    >Please note that our self-hosted agents do not include the same [pre-installed software](https://docs.microsoft.com/azure/devops/pipelines/agents/hosted) as the Microsoft-hosted agents. Also, our Build Agents are only deployed as Linux VMs. You can technically change to Windows agents, but this is out of scope for this guide.

1. Commit your changes in Git and make sure to push them to your repository. It can be on the `main` branch but this is not required. You can later select which branch to deploy from.

## Deploy self-hosted Build Agent infrastructure

Now that the pipeline for the self-hosted Agent infrastructure is imported and the settings adjusted, we are ready to deploy it. Note that this is done using the Microsoft-hosted agents. We have no requirement here yet for a self-hosted agent (plus, it would create a chicken-and-egg problem anyway).

1. Run the previously imported pipeline. Make sure to select the right branch. Select `e2e` as the environment. You can repeat the same steps later for `int` and `prod` when you are ready to use them.

    ![Run pipeline with environment selector](/docs/media/run-pipeline-with-environment-selector.png)

1. Wait until the pipeline is finished before you continue.

1. Go through the Azure Portal to your newly created Resource Group (something like `aoe2ebuildagents-rg`) to see all the resources that were provisioned for you.
1. Take a note of the name of the Resource Group. You will need it later.
1. Also, note down the name of the VNet that was provisioned within this Resource Group, something like `aoe2ebuildagents-vnet`.

    ![self-hosted agent resources in azure](/docs/media/self-hosted-agents-resources-in-azure.png)

## Configure self-hosted Build Agents in ADO

Next step is to configure our newly created Virtual Machine Scale Set (VMSS) as a self-hosted Build Agent pool in Azure DevOps. ADO will from there on control most operations on that VMSS, like scaling up and down the number of instances.

1. In Azure DevOps navigate to your project settings
1. Go to `Agent pools`
1. Add a pool and select as Pool type `Azure virtual machine scale set`
1. Select your `e2e` Service Connection and locate the VMSS.

    > **Important!** Make sure to select the scale set which ends on `-buildagents-vmss`, not the one for the Jump Servers!

1. Set the name of the pool to `e2e-private-agents` (adjust this when you create pools for other environments like `int`)
1. Check the option `Automatically tear down virtual machines after every use`. This ensures that every build run executes on a fresh VM without any leftovers from previous runs
1. Set the minimum and maximum number of agents based on your requirements. We recommend to start with a minimum of `0` and a maximum of `6`. This means that ADO will scale the VMSS down to 0 if no jobs are running to minimize costs.
1. Click Create

    ![Self-hosted Agent Pool in ADO](/docs/media/self-hosted-agents-pool-in-ado.png)

    > Setting the minimum to `0` saves money by starting build agents on demand, but can slow down the deployment process.

## Update deployment pipeline definitions

Our actual environment deployment pipelines are now ready to use the self-hosted Build Agents. For this, we need to update the pipeline definitions.

1. Go to the `/.ado/pipelines` directory and update all three `azure-release-*.yaml` (e.g. `azure-release-e2e.yaml`) files.
1. In each file, locate the following lines (almost on the top)

```yaml
pool:
  vmImage: 'ubuntu-20.04'
  #name: 'e2e-private-agents'
```

1. Remove (or comment out) the line `vmImage: 'ubuntu-20.04'` and instead uncomment line `name: 'xyz-private-agents'`. This changes the pipeline from using the Microsoft-hosted agent to your self-hosted one.
1. Repeat this for the other pipelines as well.
1. Commit the changes to git and push them.

## Set Terraform variables

As a last step before we can deploy the private version of AlwaysOn, we need to update our Terraform variables so that Terraform knows to now include Private Endpoints for the self-hosted Build Agents and lock down all other traffic.

The Terraform templates are fully prepared for this, we only need to set three additional variables.

1. Locate the variables file in the `globalresources` directory. E.g `/src/infra/workload/globalresources/variables-e2e.tfvars`. (Adjust this, based on which environment your are configuring right now).
1. Add three additional lines to the file:

```yaml
private_mode                   = true   # This switches the Terraform deployment to the private mode
buildagent_resource_group_name = "aoe2ebuildagents-rg" # <=== Change this!
buildagent_vnet_name           = "aoe2ebuildagents-vnet" # <=== Change this!
```

3. Make sure to update the values for `buildagent_resource_group_name` and `buildagent_vnet_name` to reflect your environment! You have noted down the values earlier when you checked the provisioned resources.
3. Now locate the variables file in the `releaseunit` directory. E.g `/src/infra/workload/releaseunit/variables-e2e.tfvars` and put in the same three new lines as above.
3. Commit the changes to git and push them.

## Deploy AlwaysOn in private mode

Now everything is in place to deploy the private version of AlwaysOn. Just run your deployment pipeline, for example for the E2E environment. You might notice a longer delay until the job actually starts. This is due to the fact the ADO first needs to spin up instances in the scale set before they can pick up any task.

Otherwise you should see no immediate difference in the deployment itself. However, when you check the deployed resources, you will notice differences. For example that AKS is now deployed as a private cluster or that you will not be able to see the repositories in the Azure Container Registry through the Azure Portal anymore (due to the network restrictions to only allow Private Endpoint traffic).

## Use Jump Servers to access the deployment

In order to access the now locked-down services like AKS or Key Vault, you can use the Jump Servers which were provisioned as part of the self-hosted Build Agent deployment.

1. First we need to fetch the password to log on to the Jump Servers. The password is stored in the Key Vault inside the Build Agent resource group
1. Open the Key Vault in the Azure Portal and navigate to the Access Policies blade. Add an access policy for yourself (and maybe other users as well).

    ![Access Policy](/docs/media/private_build_agent_keyvault.png)
1. Then go to the Secrets blade, and retrieve the value of the secret `vmadmin-secret`
1. Next, navigate to the Jump Server VMSS in the same resource group. E.g. `aoe2ebuildagents-jumpservers-vmss`, open the Instances blade and select one of the instances (there is probably only one)
    ![Jump Server instances](/docs/media/private_build_agent_jumpservers_instances.png)
1. Select the Bastion blade, enter `adminuser` as username and the password that you copied from Key Vault. Click Connect.
1. You now have established an SSH connection via Bastion to the Jump Server which has a direct line of sight to your private resources.
    ![SSH jump server](/docs/media/private_build_agent_jumpserver_ssh.png)
1. Use for example `az login` and `kubectl` to connect to and debug your resources.

---

[Back to documentation root](/docs/README.md)
