param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Appcomponent Azure ResourceId
  [Parameter(Mandatory = $true)]
  [string] $resourceId,

  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [string] $apiVersion = "2021-07-01-preview"
)

. "$PSScriptRoot/common.ps1"

function validateResourceId($resourceId) {
  $split = $resourceId.split("/")

  if ($split[1] -ne "subscriptions") {
    return $false
  }

  if ($split[3] -ne "resourcegroups") {
    return $false
  }

  if ($split[5] -ne "providers") {
    return $false
  }

  return $true
}

if (!(validateResourceId -resourceId $resourceId)) {
  throw "No valid resourceId provided."
}

function AppComponent {
    param
    (
      [string] $resourceName,
      [string] $resourceId,
      [string] $resourceType,
      [string] $loadTestId
    )
  
    $result = @"
    {
        "testId": "$loadTestId",
        "value": {
            "$resourceId": {
              "resourceName": "$resourceName",
              "resourceId": "$resourceId",
              "resourceType": "$resourceType"
            }
        }
    }
"@

  return $result
}

# Split Azure ResourceID
$resource = $resourceId.split("/")
$resourceType = $resource[6]+"/"+$resource[7] # combine resource type like Microsoft.ContainerService/managedCluster

$testDataFileName = $loadTestId + ".txt"
AppComponent -resourceName $resource[8] `
             -resourceType $resourceType `
             -resourceId $resourceId `
             -loadTestId $loadTestId | Out-File $testDataFileName -Encoding utf8

$urlRoot = "https://" + $apiEndpoint + "/appcomponents/" + $loadTestId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Create a new load test resource or update existing, if loadTestId already exists
az rest --url $urlRoot `
  --method PATCH `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) "Content-Type=application/merge-patch+json" `
  --url-parameters testId=$loadTestId api-version=$apiVersion `
  --body ('@' + $testDataFileName) `
  $verbose #-o none 

# Delete the access token and test data files
Remove-Item $accessTokenFileName
Remove-Item $testDataFileName