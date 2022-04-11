param
(
  [string] $resourceGroupName,
  [string] $loadTestName,
  [string] $testRunId,
  [bool]$verbose = $False
)

. "$PSScriptRoot/common.ps1"

$urlRoot = $apiEndpoint + "/testruns/" + $testRunId + "/clientMetrics"
$resourceScope = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.LoadTestService/loadtests/" + $loadTestName

# Following is to get Invoke-RestMethod to work
$resourceScopeEncoded = $resourceScope.Replace("/", "%2F")
$url = $urlRoot + "?api-version=" + $apiVersion + "&resourceId=" + $resourceScopeEncoded

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Invoke-RestMethod `
  -Uri $url `
  -Method GET `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Verbose:$verbose

Remove-Item $accessTokenFileName
