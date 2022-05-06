param
(
  # Load Test Id
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,
  
  [string] $testFileName,
  [string] $testFileId,
  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [Parameter(Mandatory = $true)]
  [string] $apiVersion
)

. "$PSScriptRoot/common.ps1"

if (!$testFileId) {
  $testFileId = (New-Guid).toString()
}

#./file-verify.ps1  -testFileName $testFileName

if (!(Test-Path $testFileName -PathType leaf)) {
  trow "File $testFileName does not exist"
}

$urlRoot = "https://" + $apiEndpoint + "/loadtests/" + $loadTestId + "/files/" + $testFileId

# Following is to get Invoke-RestMethod to work
$url = $urlRoot + "?api-version=" + $apiVersion

Write-Verbose "*** Load test service data plane: $urlRoot"

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
