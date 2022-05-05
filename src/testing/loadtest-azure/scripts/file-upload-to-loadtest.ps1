param
(
  # Load Test Id
  [string] $loadTestId,
  [string] $testFileName,
  [string] $testFileId,
  # Load Test data plane endpoint
  [string] $apiEndpoint,
  # Load Test data plane api version
  [string] $apiVersion,
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

# Following is to get Invoke-RestMethod to work
$url = $urlRoot + "?api-version=" + $apiVersion

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Invoke-RestMethod `
  -Uri $url `
  -Method PUT `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Form @{ file = Get-Item $testFileName } `
  -Verbose:$verbose -Debug

Remove-Item $accessTokenFileName
