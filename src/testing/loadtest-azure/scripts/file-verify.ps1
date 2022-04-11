param
(
  [string] $resourceGroupName,
  [string] $loadTestName,
  [string] $testFileName
)

. "$PSScriptRoot/common.ps1"

$urlRoot = $apiEndpoint + "/file/" + $testFileName + ":validate"
$resourceScope = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.LoadTestService/loadtests/" + $loadTestName

#$jsonResult = az rest --url $urlRoot `
#  --method POST `
#  --skip-authorization-header `
#  --resource $resourceScope `
#  --headers "Content-Type=application/json" ('@' + $accessTokenFileName) `
#  --url-parameters resourceId=$resourceScope api-version=$apiVersion fileName=$testFileName `
#  --body ('@' + $testFileName) $verbose

#$jsonResult

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Invoke-RestMethod `
  -Uri $urlRoot `
  -Method POST `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Form @{ 
    resourceId=$resourceScope
    'api-version'="$apiVersion"
    file = Get-Item $testFileName 
  }

