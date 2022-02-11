# Terraform-based infrastructure deployment

The Terraform-based reference implementation contains two deployment template definitions.

- The first component is the "Global Resources" part which contains all global services like CosmosDB, Azure Container Registry and Azure Front Door that a shared across multiple "release units".
- The second component is the "Release Unit" or "stamp" part that contains regional services that can be deployed into one or more regions to fulfil geographical and availability requirements.

The number and the selected regions for these "stamp" deployments can easily be changed by modifying the configuration file for a specific environment [/.ado/piplines/config/variables-values-_[env]_.yaml](/.ado/pipelines/config).

## Public and Private versions

The reference implementation can be used to deploy to different flavors of the AlwaysOn infrastructure:

- A "public" version which does not fully lock down all services, but in turn it can be deployed using Azure DevOps-hosted Build Agents. Plus, developers and administrators can more easily connect to the resources and debug them.
- A fully "private" version which locks all traffic to the services down to Private Endpoints. This provides even tighter security but requires the use of self-hosted, VNet-integrated Build Agents. Also, for any debugging etc. users most connect through Azure Bastion and Jump Servers.

Head over to [this GitHub repository](https://github.com/Azure/AlwaysOn-foundational-private) for detailed instructions how to set up the private version.

## Get started

To deploy through Terraform, you need to create a Resource Group for the Terraform state Storage Account. You can pre-create the Resource Group, Storage Account and container, but if don't, the pipeline will do it automatically for you. If you wish, you could also change the Terraform backend to Terraform Cloud etc.

```bash
## The next steps are optional. If not done manually, the pipeline will create the storage account for you.
## You need to, however, update the configuration files in any case (see below).

# Create Resource Group
az group create --location westeurope --resource-group terraformstate-rg

# Create storage account (name needs to be globally unique)
az storage account create --location <region> --name myterraformstate --resource-group  terraformstate-rg --sku Standard_ZRS

# Turn on soft delete
az storage blob service-properties delete-policy update --days-retained 7 --account-name myterraformstate --enable true

# Create tfstate container
az storage container create --account-name myterraformstate -n tfstate
```

You will need the names that you chose above when you update the variables files for the Azure DevOps pipelines ([/.ado/pipelines/README.md#configuration-files](/.ado/pipelines/README.md#configuration-files)).

## Azure Resource Providers

The following list of Azure Resource Providers needs to be registered in your subscription before starting to deploy services (this is done automatically by Terraform as part of the deployment pipeline in [steps-terraform-init.yaml](/.ado/pipelines/templates/steps-terraform-init.yaml)):

```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.EventHub
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.ContainerInstance
```

> Note: In some cases, it can take a few minutes to register a feature. Please ensure that status of a feature is reported as **Registered** before you proceed with the deployment.

Optionally, you can also check registration status of individual `Provider` by running the following command.

```bash
az provider show --namespace <provider name> --query registrationState
```

## Terraform Provider configuration

The Terraform providers used for the reference implementation are set by using a minimum supported version in the `required_providers` section.

### Local development

To edit and check the Terraform templates locally, you need to [install Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli). While you can of course also connect to your Azure Storage account that you set up earlier, the easiest way to validate your config locally - without running plan or apply - is to use `terraform init -backend=false`

Then you can run `terraform validate` to check your templates for syntax errors and many (while not all) logical errors before committing them to your repo.

## Configuration

In both folders, `./globalresources` and `./releaseunit` there are variable files per environment (`variables-[env].tfvars`), which contain Terraform-specific settings which might differ per environment. Those include scale-out settings, database units etc.

---

[Back to documentation root](/docs/README.md)
