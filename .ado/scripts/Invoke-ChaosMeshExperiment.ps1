param(
    $StampLocations, # List of Azure Regions which the env has been deployed to. The first one will be used for the experiments
    $ExperimentName, # Name of the experiment to create and run
    $ExperimentJsonPath, # Path to the JSON file which contains the experiment defintion template
    $ExperimentDurationSeconds # Duration of the experiments in seconds
)

$ChaosStudioApiVersion = "2021-09-15-preview" # REST API version for Chaos Studio

$releaseUnitInfraDeployOutput = Get-ChildItem $env:PIPELINE_WORKSPACE/terraformOutputReleaseUnitInfra/*.json | Get-Content | ConvertFrom-JSON

$subscriptionId = $(az account show -o tsv --query 'id')

echo "Deploying Chaos Experiment - $ExperimentName"

# Load experiment JSON content
$experiment = Get-Content -path $ExperimentJsonPath | ConvertFrom-Json

# Set duration
$experiment.properties.steps[0].branches[0].actions[0].duration = "PT$($ExperimentDurationSeconds)S"

# Fetch first target as template
$targetTemplate = $experiment.properties.selectors[0].targets[0]

# Remove existing template targets (replace by empty array)
$experiment.properties.selectors[0].targets = @()

$locations = $StampLocations | ConvertFrom-Json -NoEnumerate # get the stamp locations

# Use the first stamp's AKS cluster to prepare for Chaos deployment
$experimentLocation = $locations[0]

# Set location
$experiment.location = $ExperimentLocation

$stamp = $releaseUnitInfraDeployOutput.stamp_properties.value | Where-Object { $_.location -eq $experimentLocation }

$resourceGroupName = $stamp.resource_group_name

$target = $targetTemplate.PsObject.Copy()

$resourceId = $stamp.aks_cluster_id
$targetResourceId = "$resourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh"

$target.id = $targetResourceId
$experiment.properties.selectors[0].targets += $target

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

# Assign Azure Kubernetes Service Cluster Admin Role to the cluster for the experiment identity
$role = "Azure Kubernetes Service Cluster Admin Role"
echo "*** Assigning role '$role' to principal $experimentPrincipalId on $resourceId"
az role assignment create --role $role --assignee-object-id $experimentPrincipalId --scope $resourceId --assignee-principal-type ServicePrincipal

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
    echo "*** Waiting for experiment '$ExperimentName' to complete ..."
    # Wait 20sec and poll for status (again)
    Start-Sleep -Seconds 20
    $statusResult = $(az rest --method get --url $statusUrl) | ConvertFrom-Json
    echo "*** Experiment currently in state $($statusResult.properties.status)"
}
while ($statusResult.properties.status -notin "Success","Failed","Cancelled")

if ($statusResult.properties.status -eq "Failed")
{
    $statusResult.properties
    throw "*** ERROR - experiment '$ExperimentName' failed"
}

echo "*** Experiment '$ExperimentName' finished with status: $($statusResult.properties.status)"
$statusResult
