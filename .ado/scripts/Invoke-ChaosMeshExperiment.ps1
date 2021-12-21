param(
    $ExperimentName, # Name of the experiment to create and run
    $ExperimentJsonPath, # Path to the JSON file which contains the experiment defintion template
    $ExperimentLocation, # Azure Region to which to deploy the Chaos experiement
    $ExperimentDurationSeconds, # Duration of the experiments in seconds
    $ChaosStudioApiVersion # REST API version for Chaos Studio
)

$releaseUnitInfraDeployOutput = Get-ChildItem $env:PIPELINE_WORKSPACE/terraformOutputReleaseUnitInfra/*.json | Get-Content | ConvertFrom-JSON

# Use the first stamps' resource group
$resourceGroupName = $releaseUnitInfraDeployOutput.stamp_properties.value[0].resource_group_name
$subscriptionId = $(az account show -o tsv --query 'id')

echo "Deploying Chaos Experiment - $ExperimentName"

# Load experiment JSON content
$experiment = Get-Content -path $ExperimentJsonPath | ConvertFrom-Json

# Set location
$experiment.location = $ExperimentLocation

# Set duration
$experiment.properties.steps[0].branches[0].actions[0].duration = "PT$($ExperimentDurationSeconds)S"

# Fetch first target as template
$targetTemplate = $experiment.properties.selectors[0].targets[0]

# Remove existing template targets (replace by empty array)
$experiment.properties.selectors[0].targets = @()

# Loop through all AKS resource IDs and set them as targets in the JSON
foreach ($stamp in $releaseUnitInfraDeployOutput.stamp_properties.value) {
    $target = $targetTemplate.PsObject.Copy()

    $resourceId = $stamp.aks_cluster_id
    $targetResourceId = "$resourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh"

    $target.id = $targetResourceId
    $experiment.properties.selectors[0].targets += $target
}

# Convert back to JSON
$experimentJson = $experiment | ConvertTo-Json -Depth 20 -Compress

# Write experiment to temp file so we can easily upload it in the next step
$experimentJson | Set-Content -Path experiment.json

echo "*** Experiment Json: $experimentJson"

# Create Chaos experiment
$experimentCreationResult = $(az rest --method put --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Chaos/experiments/$($ExperimentName)?api-version=$($ChaosStudioApiVersion)" --body "@experiment.json") | ConvertFrom-JSON
$experimentCreationResult

$experimentId = $experimentCreationResult.id

# Get Managed Identity Id for the newly created experiment
$experimentPrincipalId = $experimentCreationResult.identity.principalId

# Assign Azure Kubernetes Service Cluster User Role to each cluster for the experiement identity
# This is required for Chaos Studio to be able to control AKS (via Chaos Mesh)
foreach ($stamp in $releaseUnitInfraDeployOutput.stamp_properties.value) {
    $resourceId = $stamp.aks_cluster_id
    $role = "Azure Kubernetes Service Cluster User Role"
    echo "*** Assigning role '$role' to principal $experimentPrincipalId on $resourceId"
    az role assignment create --role $role --assignee-object-id $experimentPrincipalId --scope $resourceId --assignee-principal-type ServicePrincipal
}

echo "*** Starting experiment '$ExperimentName' ..."
# Start the experiment
$startResult = $(az rest --method post --url "https://management.azure.com/$experimentId/start?api-version=$($ChaosStudioApiVersion)") | ConvertFrom-Json
$startResult

$statusUrl = $startResult.statusUrl

if(-not $statusUrl)
{
    throw "*** ERROR - could not fetch statusUrl for experiment '$ExperimentName'"
}

do {
    # Wait 20sec and poll for status (again)
    Start-Sleep -Seconds 20
    $statusResult = $(az rest --method get --url $statusUrl) | ConvertFrom-Json
    echo "*** Experiment '$ExperimentName' currently in state $($statusResult.properties.status). Waiting to finish ..."
}
while (($statusResult.properties.status -ne "Success") -and ($statusResult.properties.status -ne "Failed"))

echo "*** Experiment '$ExperimentName' finished with status: $($statusResult.properties.status)"
$statusResult
