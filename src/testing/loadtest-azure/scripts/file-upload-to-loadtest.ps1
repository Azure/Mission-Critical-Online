# file-upload-to-loadtest.ps1 | Upload files (jmx and others) to a load test
param
(
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2022-06-01-preview",

  # Filename to upload
  [Parameter(Mandatory = $true)]
  [string] $testFileName,
  
  # Test File ID is auto-generated when not set (default)
  [string] $testFileId = (New-Guid).toString(),

  # optional - expose outputs as pipeline variables
  [bool] $pipeline = $false,

  # if set to true script will wait till file was validated
  [bool] $wait = $true
)

. "$PSScriptRoot/common.ps1"

#./file-verify.ps1  -testFileName $testFileName

if (!(Test-Path $testFileName -PathType leaf)) {
  trow "File $testFileName does not exist"
}

$urlRoot = "https://{0}/loadtests/{1}/files/{2}"  -f $apiEndpoint, $loadTestId, $testFileId

# Following is to get Invoke-RestMethod to work
$url = "{0}?api-version={1}"  -f $urlRoot, $apiVersion

Write-Verbose "*** Load test service data plane: $urlRoot"

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

$result = Invoke-RestMethod `
  -Uri $url `
  -Method PUT `
  -Authentication Bearer `
  -Token $accessTokenSecure `
  -Form @{ file = Get-Item $testFileName } `
  -Verbose:$verbose -Debug

# export pipeline variables
if($pipeline) {
  echo "##vso[task.setvariable variable=fileId]$($result.fileId)" # contains the fileId for in-pipeline usage
} else {
  $result
}

# wait till uploaded file is validated
if($wait) {

  do {

    $fileStatus = (& $PSScriptRoot\loadtest-get-files.ps1 -apiEndpoint $apiEndpoint `
                            -loadTestId $loadTestId `
                            -fileId $($result.fileId) `
                            -keepToken $true)
    if ($fileStatus.validationStatus -ne "VALIDATION_SUCCESS") {
      Write-Verbose "*** Waiting another 10s for file validation to complete $($fileStatus.validationStatus)"
      Start-Sleep -seconds 10
    } else {
       Write-Verbose "*** File $($fileStatus.fileId) was successfully validated."
    }

  } while ($fileStatus.validationStatus -eq "VALIDATION_INITIATED" )
}

Remove-Item $accessTokenFileName

Write-Verbose "*** File $($fileStatus.filename) ($($fileStatus.fileId)) successfully uploaded to load test $loadTestId."
