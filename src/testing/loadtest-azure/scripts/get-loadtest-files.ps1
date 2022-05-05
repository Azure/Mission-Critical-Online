param
(
  # Load Test Id
  [string] $loadTestId,
  # Load Test data plane endpoint
  [string] $apiEndpoint,
  # Load Test data plane api version
  [string] $apiVersion,
  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

$urlRoot = $apiEndpoint + "/loadtests/" + $loadTestId + "/files"

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version=$apiVersion maxPageSize=$maxPageSize `
  $verbose

Remove-Item $accessTokenFileName
