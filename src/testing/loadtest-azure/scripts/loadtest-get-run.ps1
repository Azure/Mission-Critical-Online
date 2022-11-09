# loadtest-get-run.ps1 | Retrieve details from a load test run
param
(
  [Parameter(Mandatory=$true)]
  [string] $testRunId,

  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,
  
  # optional - load test data plane api version
  [string] $apiVersion = "2022-06-01-preview"
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://{0}/testruns/{1}" -f $apiEndpoint, $testRunId

$url = $urlRoot + "?api-version=" + $apiVersion

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Invoke-RestMethod `
  -Uri $url `
  -Method GET `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Verbose:$verbose

Remove-Item $accessTokenFileName
