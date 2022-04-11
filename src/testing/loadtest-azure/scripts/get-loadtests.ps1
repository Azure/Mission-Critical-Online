param
(
  [string] $resourceGroupName,
  [string] $loadTestName,
  [string] $loadTestId,
  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

#$resourceScope = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.LoadTestService/loadtests/" + $loadTestName

$urlRoot = $apiEndpoint + "/loadtests/sortAndFilter"

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
