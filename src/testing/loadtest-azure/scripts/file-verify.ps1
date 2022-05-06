param
(
  # Load Test Id
  [string] $loadTestId,
  # Load Test data plane endpoint
  [string] $apiEndpoint,
  # Load Test data plane api version
  [string] $apiVersion
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://" + $apiEndpoint + "/file/" + $testFileName + ":validate"

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
    'api-version'="$apiVersion"
    file = Get-Item $testFileName 
  }

