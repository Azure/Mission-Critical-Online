param
(
  [string] $resourceGroupName,
  [string] $loadTestName,
  [string] $loadTestId,
  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

$resourceScope = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.LoadTestService/loadtests/" + $loadTestName

$urlRoot = $apiEndpoint + "/loadtests/" + $loadTestId + "/files"

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --resource $resourceScope `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters resourceId=$resourceScope api-version=$apiVersion maxPageSize=$maxPageSize `
  $verbose

Remove-Item $accessTokenFileName
