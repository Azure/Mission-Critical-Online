param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Load Test Run Id (optional - not implemented yet)
  [string] $loadTestRunId,

  # Appcomponent Azure ResourceId
  [Parameter(Mandatory = $true)]
  [string] $resourceId,

  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [Parameter(Mandatory = $true)]
  [string] $apiVersion
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
      [string] $resourceGroup,
      [string] $resourceId,
      [string] $resourceType,
      [string] $subscriptionId,
      [string] $loadTestId,
      [string] $loadTestRunId
    )
  
    $result = @"
    {
        "testId": "$loadTestId",
        "value": {
            "$resourceId": {
              "displayName": "null",
              "kind": "null",
              "resourceName": "$resourceName",
              "resourceGroup": "$resourceGroup",
              "resourceId": "$resourceId",
              "resourceType": "$resourceType",
              "subscriptionId": "$subscriptionId"
            }
        }
    }
"@

  return $result
}

# Split Azure ResourceID
$resource = $resourceId.split("/")
$resourceType = $resource[6]+"/"+$resource[7]

$testDataFileName = $loadTestId + ".txt"
AppComponent -resourceName $resource[8] -resourceType $resourceType `
            -resourceId $resourceId -resourceGroup $resource[4] -subscriptionId $resource[2] `
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