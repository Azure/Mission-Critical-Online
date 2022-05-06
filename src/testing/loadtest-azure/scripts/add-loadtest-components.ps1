param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Appcomponent Name
  [Parameter(Mandatory = $true)]
  [string] $componentName,

  # Appcomponent Azure ResourceId
  [Parameter(Mandatory = $true)]
  [string] $componentResourceId,

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
      [string] $componentName,
      [string] $componentResourceId,
      [string] $loadTestId
    )
  
    $result = @"
    {
        "resourceId": "$componentResourceId",
        "testId": "$loadTestId",
        "testRunId": "",
        "name": "$componentName"
    }
"@

  return $result
}

$testDataFileName = $loadTestId + ".txt"
AppComponent -componentName $componentName `
            -componentResourceId $componentResourceId `
            -loadTestId $loadTestId | Out-File $testDataFileName -Encoding utf8

$urlRoot = "https://" + $apiEndpoint + "/loadtests/" + $loadTestId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Create a new load test resource or update existing, if loadTestId already exists
az rest --url $urlRoot `
  --method PATCH `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) "Content-Type=application/merge-patch+json" `
  --url-parameters testId=$loadTestId api-version=$apiVersion `
  --body ('@' + $testDataFileName) `
  -o none $verbose 

# Delete the access token and test data files
Remove-Item $accessTokenFileName
Remove-Item $testDataFileName