param(
    $StampLocations # List of Azure Regions which the env has been deployed to. The first one will be used for the experiments
)

# First we need to check if the Resource Provider was registered
$chaosRpStatus = az provider show -n Microsoft.Chaos --query "registrationState" -o tsv

if ($chaosRpStatus -ne "Registered") {
    # Not registering RP directly here since it will take too long and thus break the synchorization with Load Test
    throw "*** Resource Provider Microsoft.Chaos not yet registered. Current status: $chaosRpStatus Please run 'az provider register -n Microsoft.Chaos' first and then run the pipeline again"
}

# load json data from downloaded pipeline artifact json
$releaseUnitInfraDeployOutput = Get-ChildItem $env:PIPELINE_WORKSPACE/terraformOutputReleaseUnitInfra/*.json | Get-Content | ConvertFrom-JSON

$ChaosStudioApiVersion = "2021-09-15-preview"

$capabilities = "PodChaos-2.1", "StressChaos-2.1"

$targetResourceIds = @()

# onboard targets and capabilities for the first stamp's AKS cluster to prepare for Chaos deployment
$locations = $StampLocations | ConvertFrom-Json -NoEnumerate # get the stamp locations
$stamp = $releaseUnitInfraDeployOutput.stamp_properties.value | Where-Object { $_.location -eq $locations[0] }

$resourceId = $stamp.aks_cluster_id

# Target Resource Id is the ID of the AKS cluster with a child resource indicator
$targetResourceId = "$resourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh"
$targetResourceIds += $targetResourceId

Write-Output "*** Creating Chaos Target sub-resource: $targetResourceId "
# Create chaos target as AKS sub-resource
$url = "https://management.azure.com$($targetResourceId)?api-version=$($ChaosStudioApiVersion)"
az rest --method put --url $url --body '{\"properties\":{}}'
if ($LastExitCode -ne 0) {
    throw "*** Error on chaos target creation against $targetResourceId" # This can, for instance, happen if the region is not supported by Chaos Studio
}

$targetCreationResult # print for debug

# Enable all capabilities on the cluster
foreach ($capability in $capabilities) {
    Write-Output "*** Enabling capability $capability on sub-resource: $targetResourceId "
    $url = "https://management.azure.com$($targetResourceId)/capabilities/$($capability)?api-version=$($ChaosStudioApiVersion)"
    az rest --method put --url $url --body '{}'
    if ($LastExitCode -ne 0) {
        throw "*** Error on chaos capability '$capability' against $targetResourceId"
    }
}