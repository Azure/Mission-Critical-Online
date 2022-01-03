# Getting started

This guide describes the process and the steps to deploy AlwaysOn in your own environment/subscription from the beginning. In the end you will have an Azure DevOps organization and project set up to deploy a copy of AlwaysOn into an Azure Subscription.

## How to deploy?

AlwaysOn project is using a GitHub-based repository for version control of code artifacts and manifest files. The project leverages Azure DevOps Pipelines for build and deployment (CI/CD) pipelines.

All relevant code artifacts and manifest files are stored in the GitHub repository and can easily be forked into your own account or organization.

The document describes end-to-end process for setting up pre-requisites and other dependencies before deploying AlwaysOn in a subscription of your choice.

## Pre-requisites

Following tools and applications must be installed on the client machine which you are using to deploy AlwaysOn reference implementation:

- Install [Azure CLI](https://docs.microsoft.com/cli/azure/service-page/azure%20cli?view=azure-cli-latest)

- Install [Azure DevOps CLI](https://docs.microsoft.com/azure/devops/cli/?view=azure-devops)

- Install [PowerShell](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1).

## Overview

The process to deploy AlwaysOn is comprised of the following steps:

1) Create an [Azure DevOps organization + project](#create-a-new-azure-devops-project)
1) Create a fork of the [AlwaysOn GitHub](https://github.com/azure/alwayson) repository
1) Import [deployment pipelines](#3-import-pipelines)
1) Create [Service Principals](#create-azure-service-principal) for each individual Azure subscription
1) Create [Service Connections](#configure-service-connections) and [Variable Groups](#configure-variable-groups) in Azure DevOps
1) Access to an Azure Subscription (it is recommended to use multiple subscriptions to separate environments types i.e. dev, test and prod) with RP and preview features enabled for each of the subscriptions
1) Adjust configuration

### 1) Create a new Azure DevOps organization

To deploy AlwaysOn, you need to create a new Azure DevOps organization, or re-use an existing one. In this organization we will then create a new project used to host all pipelines for AlwaysOn.

* [Create an organization or project collection](https://docs.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops)

> **Important!** The [Azure DevOps CLI](https://docs.microsoft.com/azure/devops/cli/?view=azure-devops) is used for the subsequent steps. Please make sure that it is installed.

#### Create a new Azure DevOps project

Before we start, make sure that the [Azure DevOps CLI](https://docs.microsoft.com/azure/devops/cli/?view=azure-devops) is configured to use the Azure DevOps organization that was created in the previous step:

```bash
az devops configure --defaults organization=https://dev.azure.com/<your-org>
az devops project create --name <your-project>
```

This will result in a new project, _<your-project>_ in your Azure DevOps organization:

![New ADO Project](/docs/media/AlwaysOnGettingStarted1.png)

For all the subsequent tasks done via `az devops` or `az pipelines` the context can be set via:

```bash
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>
```

### 2) Fork the AlwaysOn GitHub repository

Azure DevOps Repos would allow us to import the AlwaysOn GitHub repository into Azure DevOps as well. For this guide we have decided to fork the repository on GitHub and use it from there.

Go to the AlwaysOn repository on GitHub and click on "Fork" in the top right corner:

![Fork GitHub Repo](/docs/media/AlwaysOnGettingStarted2Fork.png)

This will let you create a fork in your own account or organization. This is needed to allow you to make modification to our code within your own repository.

### 3) Import Pipelines

Now that we have our own fork, let us start to import the pre-created pipelines into Azure Pipelines. You can do this either manually in the Azure DevOps Portal, or via the Azure DevOps Command Line Interface (CLI). Below you find instructions for both paths.

> **Whether using Portal or CLI Pipeline import, you will need to import each Pipeline YAML file individually.**

The files to import are the YAML files stored in the `/.ado/pipelines/` directory. **Do not** import files from subdirectories, such as `/.ado/pipelines/config/` or `/.ado/pipelines/templates/`, or from other directories in the repo.

You can find more details about any of the pipelines within the [pipelines documentation](/.ado/pipelines/README.md).

To start, we will import only the following three pipelines from the `/.ado/pipelines/` directory:

* `/.ado/pipelines/azure-release-e2e.yaml`
* `/.ado/pipelines/azure-release-int.yaml`
* `/.ado/pipelines/azure-release-prod.yaml`

So repeat the steps below for each of these.

#### Import in Azure DevOps Portal

> **Important!** The Import Pipeline UI will ask you to approve needed permissions, and will show you a list of all YAML files found within the repository. See note above about which YAML files to import.

1) Go to your Azure DevOps project
1) Go to "Pipelines"
1) Click "Create pipeline" or "New pipeline"
1) Select "GitHub (YAML)"
1) Search for your repository in "Select a repository" (your fork)
1) Select "Existing Azure Pipelines YAML file"
1) Select "Run" to save and run the pipeline now, or "Save" to save and run later (see below)
1) Rename the pipeline and (optionally) move it into a folder (see below)

_Save Pipeline_

![Run or save Pipeline](/docs/media/AlwaysOnGettingStarted2RunOrSavePipeline.png 'Run or save Pipeline')

_Rename/move pipeline_

![Rename/move pipeline](/docs/media/AlwaysOnGettingStarted2PipelineRename.png 'Rename/move pipeline')

#### Import via Azure DevOps CLI

Using the `az devops` / `az pipelines` CLI:
  
> Note: If you are using Azure DevOps Repos instead of GitHub, change `--repository-type github` to `--repository-type tfsgit` in the command below. Also, if your branch is not called `main` but, for example, `master` change this accordingly.

```bash
# set the org/project context
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

# import a YAML pipeline
az pipelines create --name "Azure.AlwaysOn PROD Release" --description "Azure.AlwaysOn PROD Release" \
                    --branch main --repository https://github.com/<your-fork>/ --repository-type github \
                    --skip-first-run true --yaml-path "/.ado/pipelines/azure-release-prod.yaml"
```

You need to run the "import a YAML pipeline" CLI command above for each YAML file to import. You can browse the repo you forked to see the YAML files in the `/.ado/pipelines/` folder.


### 4) Create Azure Service Principal

All pipelines require an Azure DevOps service connection to access the target Azure Subscription where the resources are deployed. These service connections use Service Principals to access Azure which can be configured automatically, when proper access is given, or manually in Azure DevOps by providing a pre-created Azure Service Principal with the required permissions.

We need to create an AAD Service Principal with **Subscription-level Owner permissions**. We need owner permission as the pipeline will need to create various role assignments.

You need to repeat these steps for each of the environments that you want to create. But you can also only start with one for now. If so, we recommend to start with `e2e`.

```bash
# Get the subscription ID
az account show --query id -o tsv

# Output:
xxx-xxxxxxx-xxxxxxx-xxxx

# Make sure to change the name to a unique one within your tenant
az ad sp create-for-rbac --scopes "/subscriptions/xxx-xxxxxxx-xxxxxxx-xxxx" --role "Owner" --name my-alwayson-deployment-sp

# Output:
{
  "appId": "d37d23d3-d3d3-460b-a4ab-aa7a11504e76",
  "displayName": "my-alwayson-deployment-sp",
  "name": "d37d23d3-d3d3-460b-a4ab-aa7a11504e76",
  "password": "notARealP@assword-h3re",
  "tenant": "64f988bf-86f1-42af-91ab-2d7gh011db47"
}
```

Take a note of the `appId` and `password` from the output of that command as you will need it below.

More information about the required permissions needed to deploy via Terraform can be found [here](/src/infra/workload/README.md).

### 5) Create Azure Service Connections

Our AlwaysOn reference implementation knows three different environments: prod, int and e2e. These three environments can be selected for each individual pipeline run and can refer to the same or different (recommended) Azure subscriptions for proper separation. These environments are represented by service connections in Azure DevOps:

* alwayson-e2e-serviceconnection
* alwayson-prod-serviceconnection
* alwayson-int-serviceconnection

> If you only created one Service Principal above, you only need to create one Service Connection for now.

These service connections can be created in the Azure DevOps Portal or via the `az devops` CLI. Create them using either one of these two methods.

#### Use Azure DevOps Portal

1) Go to "Project settings" in Azure DevOps Portal
1) Go to "Service connections" in the "Pipelines" section
1) Click on "New service connection"
1) Select "Azure Resource Manager"
1) Select "Service principal (manual)"
1) Set the subscription details and credentials

#### Use Azure DevOps CLI

```bash
# set the org/project context
az devops configure --defaults organization=https://dev.azure.com/<your-org> project=<your-project>

export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="<service-principal-password>"

# create a new service connection
az devops service-endpoint azurerm create \
    --name alwayson-e2e-serviceconnection \
    --azure-rm-tenant-id <tenant-id> \
    --azure-rm-service-principal-id <app-id> \
    --azure-rm-subscription-id <subscription-id> \
    --azure-rm-subscription-name <subscription-name>
```

> `AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY` is used for automation purposes. If not set, `az devops` will prompt you for the service principal client secret. See [az devops service-endpoint azurerm](https://docs.microsoft.com/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest) for more information about parameters and options.

### 6) Access to an Azure Subscriptions with RP and preview features enabled

#### (Optional) Register Azure Resource Providers

> This step is also done automatically by Terraform. However, if the Service Principal that you created before does not have the required permissions to register Resource Providers, you need to do this manually with a user that has sufficient permissions.

When a new Azure Subscription is used for the first time, the required [Azure Resource Providers](/src/infra/workload/README.md#azure-resource-providers) need to be registered within the Azure Subscription.

This can be done at any time. For convenience, our infrastructure deployment pipelines do this automatically, so we are noting the need for Resource Providers here for reference only.

See [Azure Resource Providers](/src/infra/workload/README.md#azure-resource-providers) for a full list of resource providers used for AlwaysOn.

#### Register Azure preview feature

The reference implementation deployment takes a dependency on Azure Kubernetes Service AutoUpgrade and PlannedMaintenance feature which is in public preview (October 2021). Configuring an `automatic_upgrade_channel` requires registering the Azure subscription for the AutoUpgradePreview. The following command can be used to register:

``` bash
az feature register --namespace Microsoft.ContainerService -n AutoUpgradePreview
```

See [Azure Preview feature ](/src/infra/workload/README.md#preview-feature-registration-on-subscription) for additional information.

### 7) Adjust configuration

There are three variables files in the `/.ado/pipelines/config` folder, one for each environment. You need to edit those file to reflect your own workspace before you execute the first deployments.

**Please follow [this guide](/.ado/pipelines/README.md#configuration-files) to adjust the values for the different configuration files.**

#### Configure Variable Groups

As with the service connections, AlwaysOn uses individual variable groups in Azure DevOps per environment. These variable groups contain additional configuration settings that cannot or should not be stored in code - mostly secrets.

These variable groups are called `<env>-env-vg` and are loaded automatically into each pipeline based on the selected environment.

The variable groups in Azure DevOps only contain sensitive (secret) values, which must not be stored in code in the repo. They are named `[env]-env-vg` (e.g. prod-env-vg).

**Please follow [this guide](/.ado/pipelines/README.md#variable-groups) to adjust the values for the different configuration files.**

At the end you should have the following three variable groups (or less, based on how many environments you chose to configure for now):

* **e2e-env-vg** for the end-to-end validation environment
* **prod-env-vg** for the production environment
* **int-env-vg** for the integration environment

#### Create environments

Deployment pipelines taking a dependency on ADO environments. Each pipeline requires an environment created on the ADO project.

1. Click on Pipelines->Environment on the ADO project
1. Create a "New environment"

![Create new environment](/docs/media/ado-newenvironment.png)

Click on "Create"

### Execute the first deployment

After completing all previous steps in this guide, you can start executing the pipelines to spin up the infrastructure.
Go the the **Pipelines** section of the Azure DevOps Portal and click on the E2E release pipeline.

Then click **Run pipeline**:

![Run pipeline](/docs/media/devops_e2e_pipeline_header.png 'Run pipeline')

In the popup window, uncheck the box "Destroy Environment at the end" and then click **Run**.

![Start pipeline](/docs/media/devops_run_e2e_pipeline.png 'Start E2E pipeline run')

This will now kick off your first full pipeline run. You can follow the progress in the run screen:

![Pipeline run overview](/docs/media/devops_e2e_pipeline_run_screen.png)

The full run, which deploys all resources from scratch, might take around 30-40 minutes. Once all jobs are finished, take a note of the resource prefix which is now shown in the header of your pipeline screen:

![Resource tag](/docs/media/e2e_pipeline_prefix_tag.png)

### Check deployed resources

You can now go to the Azure Portal and check the provisioned resources. In the Resource Groups blade, locate the groups which start with the aforementioned prefix. You will see two resources groups (or more, depending if you changed the number of desired stamps):

![Azure Resource Groups](/docs/media/e2e_azure_resource_groups.png)

**Global Resources**
![Azure Global Resources](/docs/media/e2e_azure_resources_global.png)

**Stamp Resources**
![Azure Stamp Resources](/docs/media/e2e_azure_resources_stamp.png)


## Additional information to learn more

With the completion of at least one deployment pipeline it is now a good time to read more about the pipeline workflows and other available documentation:

Guidance on [Azure DevOps Workflows](/.ado/pipelines/README.md)

Detailed information about the infrastructure layer - [Terraform documentation](/src/infra/workload/README.md#get-started).

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
