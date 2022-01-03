# ##################################################
# This script is for CLEANUP and deletes most of the entities deployed by AzDevOps-Deploy.ps1.
# What IS deleted?
# - The pipelines deployed from YAML files in the GitHub repo. Why are these deleted in addition to deleting the project?
# --- Because deleting the pipelines explicitly also deletes the webhooks created in the GitHub repo for the pipelines
# --- Just deleting the AzDO project will of course delete the pipelines, but will NOT delete the webhooks created in the GitHub repo.
# - The AzDO project itself. This will also delete service connections, and of course anything else in the project.
#
# What is NOT deleted?
# - The Service Principal - in case you already had it existing
#
# WARNING!! This script is destructive. IT WILL DELETE THE AZURE DEVOPS PROJECT AND EVERYTHING IN THE PROJECT.
# ##################################################
# PARAMETERS

param
(
  # If not specified, this script will get it from authentication context. This is a GUID and you can get it from az account show -o tsv --query 'id'
  [string] $AzureSubscriptionId = $null,
  # Azure DevOps organizational URL, like https://dev.azure.com/YOUR_AZURE_DEV_OPS_ORG and replace YOUR_AZURE_DEV_OPS_ORG with your real value.
  [string] $AzDevOpsOrgUrl,
  # The name of the Azure DevOps project to create for AlwaysOn. If it does not exist, it will be created. If it already exists, the script will deploy into the existing project.
  [string] $AzDevOpsProjectName,
  # GitHub Personal Access Token for service connection and pipeline imports. Needs admin:repo_hook, repo.*, user.*, and must be SSO-enabled if required by your GitHub org. Manage PATs at https://github.com/settings/tokens
  [string] $GithubPAT,
  # Your individual or organizational GitHub account name, i.e. https://github.com/GITHUB_ACCOUNT_NAME. Just pass the account name, i.e. the real value instead of GITHUB_ACCOUNT_NAME from your GitHub account.
  [string] $GithubAccountName,
  # The AlwaysOn repo name in your GitHub account; usually your fork from Azure/AlwaysOn or your repo from the AlwaysOn template repo. This must already exist and contain the AlwaysOn Azure DevOps YAML pipeline files.
  [string] $GithubRepoName,
  # The branch name in your GitHub repo from which the Azure DevOps pipelines should be imported. Typically "main" but specify for your needs.
  [string] $GithubBranchName
)

# ##################################################

# Set Azure CLI to auto install extensions
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.run_after_dynamic_install=$true

# ##################################################

# Dot-source the functions
. .\AzDevOps-Functions.ps1

# ##################################################

# Get tenant and/or subscription from context if they were not otherwise specified
if (!$AzureSubscriptionId) {
  $azureAccount = Get-AzureAccount
  $AzureSubscriptionId = $azureAccount.id
}

# Get the pipelines files in the GitHub repo
$pipelineFiles = Get-PipelineFilesInGithubRepo `
  -githubRepoOwner $GithubAccountName `
  -githubPat $GithubPAT `
  -githubRepoName $GithubRepoName `
  -githubBranch $GithubBranchName

# Remove the AzDO pipelines corresponding to the files in the GitHub repo
Remove-Pipelines `
  -azureSubscriptionId $AzureSubscriptionId `
  -azdoOrgUrl $AzDevOpsOrgUrl `
  -azdoProjectName $AzDevOpsProjectName `
  -githubPat $GithubPAT `
  -pipelineFiles $pipelineFiles

# Remove the AzDO project
Remove-AzDevOpsProject `
  -azureSubscriptionId $AzureSubscriptionId `
  -azdoOrgUrl $AzDevOpsOrgUrl `
  -azdoProjectName $AzDevOpsProjectName
