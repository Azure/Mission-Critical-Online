param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [string] $apiVersion = "2021-07-01-preview"
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://" + $apiEndpoint + "/file/" + $testFileName + ":validate"

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

