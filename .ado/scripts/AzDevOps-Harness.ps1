# ##################################################
# --> Fastest Path to Azure DevOps deployment for AlwaysOn.
# Set correct values for the below variables which will be passed as parameters to AzDevOps-Deploy.ps1.
# See AzDevOps-Deploy.ps1 for additional comments/notes/requirements for the various params if unclear.
# Naturally you do not have to use this Harness script, it is here for a fastest path.
# You can also customize/pick function calls out of AzDevOps-Deploy.ps1 and build your own harness script, pipeline, etc. but this is here for your ease of use.
# ##################################################

param
(
  # This is a param so you have to pass it each time you run this script.
  # We don't want to hard-code a PAT in a file, to reduce the risk of accidentally pushing it to a GitHub repo.
  [Parameter(Mandatory=$true)]
  [string] $GithubPAT
)

[string] $AzureTenantId = $null

[string] $AzureSubscriptionId = $null
[string] $AzDevOpsEnvironmentName = "e2e"

[string] $AzDevOpsOrgUrl = "https://dev.azure.com/YOUR_AZDO_ORG_NAME"
[string] $AzDevOpsProjectName = "YOUR_AZDO_PROJECT_NAME"

[string] $ServicePrincipalName = "YOUR_AZURE_SERVICE_PRINCIPAL_NAME"
[string] $GithubAccountName = "YOUR_GITHUB_ACCT_NAME"
[string] $GithubRepoName = "YOUR_GITHUB_REPO_NAME"
[string] $GithubBranchName = "YOUR_GITHUB_BRANCH_NAME"

# Variable values from AADB2C - mock values here; replace with real values
[string] $SmokeTestUserName = "user@demo.always-on.app"
$AzDevOpsVariables = @{
  "b2cResultWorkerClientSecret" = "myb2cResultWorkerClientSecretValue"
  "loadtestUserPassword" = "myLoadtestUserPassword"
  "smokePassword" = "mySmokePassword"
}

# Deploy and Remove toggles
[bool] $deploy = $true
[bool] $remove = $false

if ($deploy) {
  .\AzDevOps-Deploy.ps1 `
    -AzureTenantId $AzureTenantId `
    -AzureSubscriptionId $AzureSubscriptionId `
    -AzDevOpsOrgUrl $AzDevOpsOrgUrl `
    -AzDevOpsProjectName $AzDevOpsProjectName `
    -AzDevOpsEnvironmentName $AzDevOpsEnvironmentName `
    -ServicePrincipalName $ServicePrincipalName `
    -GithubPAT $GithubPAT `
    -GithubAccountName $GithubAccountName `
    -GithubRepoName $GithubRepoName `
    -GithubBranchName $GithubBranchName `
    -SkipFirstPipelineRun $true `
    -SmokeTestUserName $SmokeTestUserName `
    -AzDevOpsVariables $AzDevOpsVariables
}

if ($remove) {
  .\AzDevOps-Remove.ps1 `
    -AzureSubscriptionId $AzureSubscriptionId `
    -AzDevOpsOrgUrl $AzDevOpsOrgUrl `
    -AzDevOpsProjectName $AzDevOpsProjectName `
    -GithubPAT $GithubPAT `
    -GithubAccountName $GithubAccountName `
    -GithubRepoName $GithubRepoName `
    -GithubBranchName $GithubBranchName
}
