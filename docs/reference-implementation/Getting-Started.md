# Getting started

This step-by-step guide describes the process to deploy Azure Mission-Critical in your own environment from the beginning. At the end of this guide you will have an Azure DevOps organization and project set up to deploy a copy of the Azure Mission-Critical reference implementation into an Azure Subscription.

**This guide describes the steps to get started using the Azure DevOps Portal (UI) only. To create the set up through the Azure CLI only follow [this guide](./Getting-Started-CLI.md) instead.**

## How to deploy?

The Azure Mission-Critical project is using a GitHub repository for version control of code artifacts and manifest files. The project leverages Azure DevOps Pipelines for build and deployment (CI/CD) pipelines.

> Instead of GitHub also other Git-based repositories can be used, such as *Azure DevOps Repos*.

All relevant code artifacts and manifest files are stored in this GitHub repository and can easily be forked into your own account or organization.

This guide describes the end-to-end process for setting up all pre-requisites and dependencies before deploying Azure Mission-Critical into an Azure subscription of your choice.

## Pre-requisites

The Azure Mission-Critical reference implementation gets deployed into an Azure Subscription. For this you will need a **Service Principal (SPN) with Owner permissions on that subscription.**

- Either your user needs to have **Owner** or **User Access Administrator (UAA)** permission and you have **the right to create new Service Principals** on your Azure AD tenant, or
- You need to have a pre-provisioned Service Principal with Owner permissions on the subscription

If you will create the Service Principal yourself, it is recommended to have either [Azure CLI](https://learn.microsoft.com/cli/azure/service-page/azure%20cli?view=azure-cli-latest) installed on your machine or have access to it through the [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/).

> **Note!** Azure Mission-Critical reference implementation uses functionalities that are general available (GA). However, at the moment the deployment requires Azure AD workload identity for AKS which is only available in preview. Make sure that the feature is registered on your subscription and Resource Provider following [this documentation](https://learn.microsoft.com/azure/aks/workload-identity-deploy-cluster#register-the-enableworkloadidentitypreview-feature-flag).

## Overview

The process to deploy Azure Mission-Critical is comprised of the following steps:

1) Create an [Azure DevOps organization and project](#1-create-a-new-azure-devops-organization-and-project)
1) Generate your own repository based on the Azure Mission-Critical [GitHub template](#2-generate-your-own-repository-based-on-the-azure-mission-critical-github-template) repository
1) Import [deployment pipelines](#3-import-deployment-pipelines)
1) Create [Service Principals](#4-create-azure-service-principal) for each individual Azure subscription
1) Create [Service Connections](#5-create-azure-service-connections) in Azure DevOps
1) [Adjust configuration](#6-adjust-configuration)
1) [Execute the first deployment](#7-execute-the-first-deployment)
1) [Check deployed resources](#8-check-deployed-resources)

> If you run into any issues during the deployment, consult the [Troubleshooting guide](./Troubleshooting.md).

### 1) Create a new Azure DevOps organization and project

To deploy the Azure Mission-Critical reference implementation, you need to create a new Azure DevOps organization, or re-use an existing one. In this organization you will then create a new project used to host all pipelines for Azure Mission-Critical.

- [Create an organization or project collection](https://learn.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops)


#### Create a new Azure DevOps project

Once you have created an Azure DevOps organization, you can create a new project in that organization. Go to the Azure DevOps portal, select the desired Organization and Click on "+ New Project" in the upper right hand corner.

Select a name and set the visibility. Both "Enterprise" or "Private" are fine for this walkthrough.

This will result in a new project, `<your-project>` in your Azure DevOps organization:

![New ADO Project](/docs/media/AlwaysOnGettingStarted1.png)

### 2) Generate your own repository based on the Azure Mission-Critical GitHub template

Azure DevOps Repos would allow us to import the Azure Mission-Critical reference implementation GitHub repository into Azure DevOps as well. For this guide we have decided to generate our own repository based on the template on GitHub and use it from there.

Sign into GitHub and go to the root of the Azure Mission-Critical reference implementation repository on GitHub and click on [Use this template](https://github.com/Azure/Mission-Critical-Online/generate) in the top right corner':

![Use GitHub Repo template](/docs/media/GettingStarted-template.png)

This will let you create a repository in your own account or organization. This is needed to allow you to make modification to our code within your own repository.

### 3) Import deployment pipelines

Now that you have your own repo, let's start to import the pre-created pipelines into Azure Pipelines.

The files to import are the YAML files stored in the `/.ado/pipelines/` directory. **Do not** import files from subdirectories, such as `/.ado/pipelines/config/` or `/.ado/pipelines/templates/`, or from other directories in the repo.

You can find more details about any of the pipelines within the [pipelines documentation](/.ado/pipelines/README.md).

To start, you will import **only** the following pipeline from the `/.ado/pipelines/` directory:

- `/.ado/pipelines/azure-release-e2e.yaml`

When you are later ready to also deploy further environments such as INT (integration) and PROD (production), repeat the same steps (and consecutive actions below) for the respective  pipelines:

- `/.ado/pipelines/azure-release-int.yaml`
- `/.ado/pipelines/azure-release-prod.yaml`

#### Import in Azure DevOps Portal

> **Important!** The Import Pipeline UI will ask you to approve needed permissions, and will show you a list of all YAML files found within the repository. See note above about which YAML files to import.

1) Go to your Azure DevOps project
1) Go to "Pipelines"
1) Click "Create pipeline" or "New pipeline"
1) Select "GitHub (YAML)"

   > **Note!** If requested, grant the Azure Pipelines app permissions to access your GitHub repository.

   ![github authorization](/docs/media/github-ado-auth-1.png)

1) Search for your repository in "Select a repository" (name of your template)

   > **Note!** If requested, grant the Azure Pipelines app permissions to access your GitHub repository.

1) Select "Existing Azure Pipelines YAML file" in the "Configure your pipeline" dialog and click "Continue"

   > **Note!** In the "Select an existing YAML file" dialog, select the YAML file you want to import. For the e2e pipeline this is `/.ado/pipelines/azure-release-e2e.yaml`.

   ![select yaml pipline](/docs/media/AlwaysOnGettingStarted2Pipeline_select_yaml_pipeline.png)

1) Select "Save" (from the dropdown menu under the "Run" button) to save the pipeline

   ![Run or save Pipeline](/docs/media/AlwaysOnGettingStarted2RunOrSavePipeline.png 'Run or save Pipeline')

1) Rename the pipeline by clicking on the three dots and (optionally) move it into a folder (see below).  The UI usually doesn't immediately reflect the change, so just refresh the page.

   ![Rename/move pipeline](/docs/media/AlwaysOnGettingStarted2PipelineRename.png 'Rename/move pipeline')

### 4) Create Azure Service Principal

> This step can be skipped if a Service Principal was pre-provisioned.

All pipelines require an Azure DevOps service connection to access the target Azure Subscription where the resources are deployed. These service connections use Service Principals to access Azure which can be configured automatically, when proper access is given, or manually in Azure DevOps by providing a pre-created Azure Service Principal with the required permissions.

> **Important!** The AAD Service Principal needs **subscription-level owner permissions** as the pipeline will create various role assignments.

You need to repeat these steps for each of the environments that you want to create. But you can also only start with one for now. If so, we recommend to start with `e2e`.

```powershell
# Get the subscription ID
az account show --query id -o tsv

# Output:
xxx-xxxxxxx-xxxxxxx-xxxx

# Verify that this is indeed the subscription you want to target. Otherwise you can switch the scope using:
# az account set --subscription <name>

# Make sure to change the name to a unique one within your tenant. You must have Azure CLI version 2.25.0 or later.
az ad sp create-for-rbac --scopes "/subscriptions/xxx-xxxxxxx-xxxxxxx-xxxx" --role "Owner" --name <CHANGE-MY-NAME-alwayson-deployment-sp>

# Output:
{
  "appId": "d37d23d3-d3d3-460b-a4ab-aa7a11504e76",
  "displayName": "my-alwayson-deployment-sp",
  "password": "notARealP@assword-h3re",
  "tenant": "64f988bf-86f1-42af-91ab-2d7gh011db47"
}
```

Take a note of the `appId` and `password` from the output of that command as you will need it below.

More information about the required permissions needed to deploy via Terraform can be found [here](/src/infra/workload/README.md).

### 5) Create Azure Service Connections

Our Azure Mission-Critical reference implementation knows three different environments: prod, int and e2e. These three environments can be selected for each individual pipeline run and can refer to the same or different (recommended) Azure subscriptions for proper separation. These environments are represented by service connections in Azure DevOps:

> **Important!** Since these connection names are used in pipelines, use them exactly as specified below. If you change the name of the service connection, you have to also change it in pipeline YAML.

- `alwayson-e2e-serviceconnection`
- `alwayson-prod-serviceconnection`
- `alwayson-int-serviceconnection`

> If you only created one Service Principal above, you only need to create one Service Connection for now.

When you create the service connections, make sure that you specify the right credentials for the **service principal created earlier**.

#### Use Azure DevOps Portal

1) Go to "Project settings" in Azure DevOps Portal
1) Go to "Service connections" in the "Pipelines" section
1) Click on "New service connection"
1) Select "Azure Resource Manager"
1) Select "Service principal (manual)"
1) Set the subscription details and credentials
1) Set the service connection name to one of the three above
1) Click on "Verify and save"

### 6) Adjust configuration

There are three variables files in the `/.ado/pipelines/config` folder, one for each environment. You need to edit these files to reflect your own workspace before you execute the first deployments. They are named `variables-values-[env].yaml`.

Modify the respective file for the environment which you want to deploy. At least the variables which are marked as `required` in the table below need to be changed.

| Required to modify | Key | Description | Sample value |
| --- | --- | --- | --- |
| **YES** | prefix | Custom prefix used for Azure resources. **Must not be longer than 6 characters!** | mye2e |
| **YES** | contactEmail | E-mail alias used for alerting. **Be careful which address you put in here as it will potentially receive a lot of notification emails** | alwaysonappnet@example.com |
| NO | terraformResourceGroup | Resource Group where the Terraform state Storage account will be deployed | terraformstate-rg |
| NO | stampLocations | List of locations (Azure Regions) where this environment will be deployed into. You can keep the default to start with.  | ["northeurope", "eastus2"] |
| NO | envDnsZoneRG | OPTIONAL: Name of the Azure Resource group which holds the Azure DNS Zone for your custom domain. Not required if you do not plan to use a custom DNS name | mydns-rg |
| NO | envDomainName | OPTIONAL: Name of the Azure DNS Zone. Not required if you do not plan to use a custom DNS name | example.com |

**After modifying the file, make sure to commit and push the changes to your Git repository.**

For more details on the variables, you can consult [this guide](/.ado/pipelines/README.md#configuration-files).


### 7) Execute the first deployment

After completing all previous steps in this guide, you can start executing the pipelines to spin up the infrastructure.
Go the the **Pipelines** section of the Azure DevOps Portal and click on the E2E release pipeline.

Then click **Run pipeline**:

![Run pipeline](/docs/media/devops_e2e_pipeline_header.png 'Run pipeline')

In the popup window, **uncheck** the box **Destroy environment at the end** and then click **Run**.

![Start pipeline](/docs/media/devops_run_e2e_pipeline.png 'Start E2E pipeline run')

This will now kick off your first full pipeline run. You can follow the progress in the run screen:

![Pipeline run overview](/docs/media/devops_e2e_pipeline_run_screen.png)

Upon the first execution of a pipeline, Azure DevOps might ask you to grant permissions on the required service connection to Azure, as well as the environment.

![Pipeline permission](/docs/media/AlwaysOnGettingStarted2PipelinePermission.png)

Click on **View** and then on **Permit** for each required permission.

![Pipeline permission](/docs/media/AlwaysOnGettingStarted2PipelinePermissionGrant.png)

After this, the pipeline execution will kick off.

> If you run into any issues during the deployment, consult the [Troubleshooting guide](./Troubleshooting.md).

The full run, which deploys all resources from scratch, might take around 30-40 minutes. Once all jobs are finished, **take a note of the resource prefix** which is now shown in the header of your pipeline screen:

![Resource tag](/docs/media/e2e_pipeline_prefix_tag.png)

### 8) Check deployed resources

You can now go to the Azure Portal and check the provisioned resources. In the Resource Groups blade, locate the groups which start with the aforementioned prefix. You will see two resources groups (or more, depending if you changed the number of desired stamps):

![Azure Resource Groups](/docs/media/e2e_azure_resource_groups.png)

**Global Resources**
![Azure Global Resources](/docs/media/e2e_azure_resources_global.png)

**Stamp Resources**
![Azure Stamp Resources](/docs/media/e2e_azure_resources_stamp.png)

#### Browse to the demo app website

We can now browse to the demo app website. Fetch the URL from the Front Door resource:

1) Find the "Global Resource" group, e.g. `<myprefix>123-global-fd`
1) Click on the Front Door resource (e.g. `<myprefix>123-global-fd`)
1) Click on the "Frontend host" link
![Frontend host](/docs/media/frontdoor-resource-hostlink.png)
1) This opens the landing page of the demo app. Feel free to browse around!

![landingpage](/docs/media/website_landingpage.png)

![catalogpage](/docs/media/website_catalogpage.png)

## Additional information to learn more

With the completion of at least one deployment pipeline it is now a good time to read more about the pipeline workflows and other available documentation:

- Guidance on [Azure DevOps Workflows](/.ado/pipelines/README.md)

- Detailed information about the infrastructure layer - [Terraform documentation](/src/infra/workload/README.md#get-started).

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
