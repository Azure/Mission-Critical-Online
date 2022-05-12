# loadtest-get-files.ps1 | List all files uploaded to a load test
param
(
  # Load Test Id
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [string] $apiVersion = "2021-07-01-preview",

  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://" + $apiEndpoint + "/loadtests/" + $loadTestId + "/files"

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version=$apiVersion maxPageSize=$maxPageSize `
  $verbose

Remove-Item $accessTokenFileName
