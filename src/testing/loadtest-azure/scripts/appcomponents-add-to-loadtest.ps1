param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Appcomponent Name
  [Parameter(Mandatory = $true)]
  [string] $resourceName,
  [string] $resourceGroup,
  [string] $resourceType,
  [string] $subscriptionId,

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

function AppComponent {
    param
    (
      [string] $resourceName,
      [string] $resourceGroup,
      [string] $resourceId,
      [string] $resourceType,
      [string] $subscriptionId,
      [string] $loadTestId
    )
  
    $result = @"
    {
        "testId": "$loadTestId",
        "value": {
            "$resourceId": {
              "displayName": null,
              "kind": null,
              "resourceName": "$resourceName",
              "resourceGroup": "$resourceGroup"
              "resourceId": "$resourceId",
              "resourceType": "$resourceType",
              "subscriptionId": "$subscriptionId"
            }
        }
    }
"@

  Write-Host $result
  return $result
}

$testDataFileName = $loadTestId + ".txt"
AppComponent -resourceName $resourceName -resourceType $resourceType `
            -resourceId $resourceId -resourceGroup $resourceGroup -subscriptionId $subscriptionId `
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