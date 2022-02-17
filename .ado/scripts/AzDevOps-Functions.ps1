# ##################################################
# This file contains various PowerShell functions written to simplify Azure DevOps and GitHub provisioning activities.
# To use, dot-source this file from another PowerShell file. This is how:
# . .\AzDevOps-Functions.ps1
# (Note the extra dot on the line before this filename)
# AzDevOps-Deploy.ps1 uses the functions in this file by dot-sourcing it.
# You will note that the functions herein contain redundancy. For example, several functions each call Install-AzDevOpsExtension.
# This is to avoid any implicit dependencies between the functions, so that you can more easily create custom deployment scripts based on AzDevOps-Deploy.ps1,
#   and can use some of these functions without running into dependency problems.
# ##################################################

# This function is not needed if Azure CLI is configured to automatically install extensions
function Install-AzDevOpsExtension {
  az extension add --name azure-devops --upgrade --yes
}

function Get-AzureAccount {
  $azureAccount = (az account show) | ConvertFrom-Json

  return $azureAccount
}

# https://docs.microsoft.com/cli/azure/devops#az_devops_configure
function Set-AzDevOpsDefaults {
  param
  (
    [string] $azdoOrgUrl,
    [string] $azdoProjectName
  )
  az devops configure --defaults organization=$azdoOrgUrl project=$azdoProjectName
}

# Organizations can ONLY be created manually via AzDO portal - placeholder here FYI
# https://docs.microsoft.com/azure/devops/organizations/accounts/create-organization

function New-ServicePrincipal {
  param
  (
    [string] $azureSubscriptionId,
    [string] $servicePrincipalName
  )

  $scope = "/subscriptions/" + $azureSubscriptionId

  $sp = (az ad sp create-for-rbac --scopes $scope --role "Owner" --name $servicePrincipalName) | ConvertFrom-Json

  return $sp
}

# https://docs.microsoft.com/cli/azure/devops/project
function New-AzDevOpsProject {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $azdoProjectVisibility = "private"
  )

  # Check for existence
  $project = (az devops project show --subscription $azureSubscriptionId --org $azdoOrgUrl -p $azdoProjectName)

  if (!$project) {
    az devops project create `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --name $azdoProjectName `
      --visibility $azdoProjectVisibility
  }  
}

function Remove-AzDevOpsProject {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName
  )

  $id = (az devops project show --subscription $azureSubscriptionId --org $azdoOrgUrl -p $azdoProjectName -o tsv --query 'id')

  az devops project delete --yes `
  --subscription $azureSubscriptionId `
  --org $azdoOrgUrl `
  --id $id
}

function New-AzDevOpsVariableGroup {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $azdoVariableGroupName,
    [string] $variableName,
    [string] $variableValue,
    [bool] $allPipelines = $true
  )

  # Check for existence
  $vgId = (az pipelines variable-group list `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --group-name $azdoVariableGroupName -o tsv --query '[0].id')

  if (!$vgId) {
    $vgId = (az pipelines variable-group create `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --name $azdoVariableGroupName `
      --variables ${variableName}="${variableValue}" `
      --authorize $allPipelines `
      -o tsv `
      --query 'id'
    )
  } else {
    Update-AzDevOpsVariableGroup `
      -azureSubscriptionId $azureSubscriptionId `
      -azdoOrgUrl $azdoOrgUrl `
      -azdoProjectName $azdoProjectName `
      -azdoVariableGroupId $vgId `
      -azdoVariableGroupName $azdoVariableGroupName `
      -allPipelines $allPipelines

      New-AzDevOpsVariable `
        -azureSubscriptionId $azureSubscriptionId `
        -azdoOrgUrl $azdoOrgUrl `
        -azdoProjectName $azdoProjectName `
        -azdoVariableGroupId $vgId `
        -variableName $variableName `
        -variableValue $variableValue `
        -secret $false
  }

  return $vgId
}

function Update-AzDevOpsVariableGroup {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [int] $azdoVariableGroupId,
    [string] $azdoVariableGroupName,
    [bool] $allPipelines = $true
  )

  az pipelines variable-group update `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --group-id $azdoVariableGroupId `
    --name $azdoVariableGroupName `
    --authorize $allPipelines `
    -o none
}

function New-AzDevOpsVariable {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [int] $azdoVariableGroupId,
    [string] $variableName,
    [string] $variableValue,
    [bool] $secret
  )

  # Check for existence
  $exists = (az pipelines variable-group variable list `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --group-id $azdoVariableGroupId `
    --query "$variableName"
  )

  if (!$exists) {
    az pipelines variable-group variable create `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --group-id $azdoVariableGroupId `
      --name $variableName `
      --value $variableValue `
      --secret $secret `
      -o none
  } else {
    Update-AzDevOpsVariable `
      -azureSubscriptionId $azureSubscriptionId `
      -azdoOrgUrl $azdoOrgUrl `
      -azdoProjectName $azdoProjectName `
      -azdoVariableGroupId $azdoVariableGroupId `
      -variableName $variableName `
      -variableValue $variableValue `
      -secret $secret
  }
}

function Update-AzDevOpsVariable {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [int] $azdoVariableGroupId,
    [string] $variableName,
    [string] $variableValue,
    [bool] $secret
  )

  az pipelines variable-group variable update `
  --subscription $azureSubscriptionId `
  --org $azdoOrgUrl `
  --project $azdoProjectName `
  --group-id $azdoVariableGroupId `
  --name $variableName `
  --value $variableValue `
  --secret $secret `
  -o none
}

function New-GithubServiceConnection {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubServiceConnectionName,
    [string] $githubPat,
    [string] $githubRepoUrl
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  $githubServiceConnectionId = (az devops service-endpoint list --verbose `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    -o tsv `
    --query "[?name == '$githubServiceConnectionName'].id")

  # Create GitHub service connection if it doesn't exist yet - this will prompt for secret if not set to AZURE_DEVOPS_EXT_GITHUB_PAT env var above
  if (!$githubServiceConnectionId) {
    $githubServiceConnectionId = (az devops service-endpoint github create --verbose `
        --subscription $azureSubscriptionId `
        --org $azdoOrgUrl `
        --project $azdoProjectName `
        --github-url $githubRepoUrl `
        --name $githubServiceConnectionName `
        -o tsv --query 'id')
  
    # Allow all pipelines to use service connection
    # This has to have output set to none so that the function can return just the new GitHub service connection ID
    # Otherwise a block of JSON is emitted by this which interferes with ability to set output to a variable
    az devops service-endpoint update `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --id $githubServiceConnectionId `
      --enable-for-all true `
      --output none
  }

  return $githubServiceConnectionId
}

function New-AzureServiceConnection {
  param
  (
    [string] $azureTenantId,
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $azureServiceConnectionName,
    $servicePrincipal
  )

  # Get the subscription name - required param for Azure service connection create
  $azureSubscriptionName = (az account show --subscription $azureSubscriptionId -o tsv --query 'name')

  # If password is present, we can use it. Otherwise the script will ask for it interactively.
  if ($servicePrincipal.password) {
    # For automation have to set the Service Principal password to this env var
    # https://docs.microsoft.com/cli/azure/devops/service-endpoint/azurerm#az_devops_service_endpoint_azurerm_create
    $env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $servicePrincipal.password
  }

  $azureServiceConnectionId = (az devops service-endpoint list --verbose `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    -o tsv `
    --query "[?name == '$azureServiceConnectionName'].id")

  # Create Azure service connection if it doesn't exist yet - this will prompt for secret if not set to AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY env var above
  if (!$azureServiceConnectionId) {
    $azureServiceConnectionId = (az devops service-endpoint azurerm create --verbose `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --azure-rm-tenant-id $azureTenantId `
      --azure-rm-subscription-id $azureSubscriptionId `
      --azure-rm-subscription-name $azureSubscriptionName `
      --azure-rm-service-principal-id $servicePrincipal.appId `
      --name $azureServiceConnectionName `
      -o tsv --query 'id')

    # Allow all pipelines to use service connection
    az devops service-endpoint update `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --id $azureServiceConnectionId `
      --enable-for-all true
  }
}

function Get-PipelineFilesInGithubRepo {
  param
  (
    [string] $githubRepoOwner,
    [string] $githubPat,
    [string] $githubRepoName,
    [string] $githubBranch,
    [string] $azdoEnvName = $null
  )

  $envReleaseInfix = "-release-"

  # AzDO template path in GitHub repo - this path is required exactly like this so no need to parameterize
  $githubRepoTemplatePath = "/.ado/pipelines"

  $githubApiUri = "https://api.github.com/repos/${githubRepoOwner}/${githubRepoName}/contents${githubRepoTemplatePath}?ref=${githubBranch}"

  $githubFiles = curl -H "Accept: application/vnd.github.v3+json" -u ${githubRepoOwner}:${githubPat} $githubApiUri | ConvertFrom-Json

  $githubFiles = $githubFiles.Where{ $_.name -match '.yaml' -or $_.name -match '.yml' }
  $githubFiles = $githubFiles.Where{ (!$azdoEnvName) -or $_.name -notmatch $envReleaseInfix -or ($_.name -match $envReleaseInfix -and $_.name -match $azdoEnvName) }

  return $githubFiles
}

function Import-Pipelines {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubPat,
    [string] $githubRepoUrl,
    [string] $githubBranch,
    [string] $githubServiceConnectionId,
    [bool] $skipFirstPipelineRun,
    $pipelineFiles
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  $pipelineFiles | ForEach-Object {
    New-Pipeline `
      -azureSubscriptionId $azureSubscriptionId `
      -azdoOrgUrl $azdoOrgUrl `
      -azdoProjectName $azdoProjectName `
      -githubPat $githubPat `
      -githubRepoUrl $githubRepoUrl `
      -githubBranch $githubBranch `
      -githubServiceConnectionId $githubServiceConnectionId `
      -skipFirstPipelineRun $skipFirstPipelineRun `
      -pipelineName $_.name `
      -yamlPath $_.path
  }
}

function New-Pipeline {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubPat,
    [string] $githubRepoUrl,
    [string] $githubBranch,
    [string] $githubServiceConnectionId,
    [bool] $skipFirstPipelineRun,
    [string] $pipelineName,
    [string] $yamlPath
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  # Check for existence
  $id = (az pipelines show `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --name $pipelineName `
    -o tsv `
    --query "id"
  )

  if (!$id) {
    az pipelines create --verbose `
      --subscription $azureSubscriptionId `
      --org $azdoOrgUrl `
      --project $azdoProjectName `
      --name $pipelineName `
      --repository-type github `
      --repository $githubRepoUrl `
      --branch $githubBranch `
      --service-connection $githubServiceConnectionId `
      --yaml-path $yamlPath `
      --skip-first-run $skipFirstPipelineRun
  } else {
    Update-Pipeline `
      -azureSubscriptionId $azureSubscriptionId `
      -azdoOrgUrl $azdoOrgUrl `
      -azdoProjectName $azdoProjectName `
      -githubPat $githubPat `
      -githubBranch $githubBranch `
      -pipelineId $id `
      -yamlPath $yamlPath
  }
}

function Update-Pipeline {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubPat,
    [string] $githubBranch,
    [int] $pipelineId,
    [string] $yamlPath
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  az pipelines update `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --id $pipelineId `
    --branch $githubBranch `
    --yaml-path $yamlPath
}

function Remove-Pipeline {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubPat,
    [string] $pipelineName
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  $id = (az pipelines show `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --name $pipelineName `
    -o tsv `
    --query 'id')

  az pipelines delete --yes `
    --subscription $azureSubscriptionId `
    --org $azdoOrgUrl `
    --project $azdoProjectName `
    --id $id
}

function Remove-Pipelines {
  param
  (
    [string] $azureSubscriptionId,
    [string] $azdoOrgUrl,
    [string] $azdoProjectName,
    [string] $githubPat,
    $pipelineFiles
  )

  $env:AZURE_DEVOPS_EXT_GITHUB_PAT = $githubPat

  $pipelineFiles | ForEach-Object {
    Remove-Pipeline `
      -azureSubscriptionId $azureSubscriptionId `
      -azdoOrgUrl $azdoOrgUrl `
      -azdoProjectName $azdoProjectName `
      -githubPat $githubPat `
      -pipelineName $_.name
  }
}