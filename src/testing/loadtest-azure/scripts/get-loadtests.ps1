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

$urlRoot = "https://" + $apiEndpoint + "/loadtests/sortAndFilter"

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version="$apiVersion" testId="$loadTestId" maxPageSize=$maxPageSize `
  $verbose

#az rest --url $urlRoot `
#  --method GET `
#  --skip-authorization-header `
#  --resource "$resourceScope" `
#  --headers ('@' + $accessTokenFileName) `
#  --url-parameters resourceId="$resourceScope" api-version="$apiVersion" testId="$loadTestId" maxPageSize=$maxPageSize `
#  $verbose

Remove-Item $accessTokenFileName
