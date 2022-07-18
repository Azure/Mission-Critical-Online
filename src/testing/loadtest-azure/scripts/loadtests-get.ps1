# loadtests-get.ps1 | List existing load tests
param
(
  # Load Test Id (optional)
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [string] $apiVersion = "2022-06-01-preview",

  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://" + $apiEndpoint + "/loadtests/sortAndFilter"

if (!$loadTestId) {
  $urlRoot = $urlRoot + "?testId=" + $loadTestId
}

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version="$apiVersion" maxPageSize=$maxPageSize `
  $verbose

Remove-Item $accessTokenFileName
