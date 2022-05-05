param
(
  [string] $loadTestName,
  [string] $loadTestId,
  [string] $testFileName,
  [string] $testFileId,
  [string] $apiEndpoint,
  [bool]$verbose = $False
)

. "$PSScriptRoot/common.ps1"

if (!$testFileId) {
  $testFileId = (New-Guid).toString()
}

#./file-verify.ps1 -resourceGroupName $resourceGroupName -loadTestName $loadTestName -testFileName $testFileName

if (!(Test-Path $testFileName -PathType leaf)) {
  echo "File $testFileName does not exist"
  exit 0
}

$urlRoot = $apiEndpoint + "/loadtests/" + $loadTestId + "/files/" + $testFileId
$resourceScope = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.LoadTestService/loadtests/" + $loadTestName

# Following is to get Invoke-RestMethod to work
$resourceScopeEncoded = $resourceScope.Replace("/", "%2F")
$url = $urlRoot + "?api-version=" + $apiVersion + "&resourceId=" + $resourceScopeEncoded

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Invoke-RestMethod `
  -Uri $url `
  -Method PUT `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Form @{ file = Get-Item $testFileName } `
  -Verbose:$verbose

Remove-Item $accessTokenFileName
