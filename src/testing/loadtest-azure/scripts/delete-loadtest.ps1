param
(
  [string] $resourceGroupName,
  [string] $loadTestName,
  [string] $loadTestId
)

. ./common.ps1

$resourceScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.LoadTestService/loadtests/$loadTestName"

$urlRoot = $apiEndpoint + "/loadtests/" + "$loadTestId"

az rest --url $urlRoot `
  --method DELETE `
  --skip-authorization-header `
  --resource $resourceScope `
  --headers "$accessTokenHeader" `
  --url-parameters resourceId="$resourceScope" testId="$loadTestId" api-version="$apiVersion" `
  $verbose
