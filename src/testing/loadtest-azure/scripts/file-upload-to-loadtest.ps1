# file-upload-to-loadtest.ps1 | Upload files (jmx and others) to a load test
param
(
  [Parameter(Mandatory = $true)]
  [string] $loadTestId,

  # Load Test data plane endpoint
  [Parameter(Mandatory = $true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2023-04-01-preview",

  # Filename to upload
  [Parameter(Mandatory = $true)]
  [string] $testFileName,
  
  # Test File ID is auto-generated when not set (default)
  [string] $testFileId = "$(New-Guid).jmx",

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

$urlRoot = "https://{0}/tests/{1}/files/{2}"  -f $apiEndpoint, $loadTestId, $testFileId

Write-Verbose "*** Load test service data plane: $urlRoot"

$result = az rest --url $urlRoot `
  --method PUT `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) "Content-Type=application/octet-stream" `
  --url-parameters api-version=$apiVersion fileType="JMX_FILE" `
  --body ('@' + $testFileName) `
  --output json $verbose | ConvertFrom-Json

# export pipeline variables
if($pipeline) {
  echo "##vso[task.setvariable variable=fileId]$($result.fileName)" # contains the fileName for in-pipeline usage
} else {
  $result
}

# wait till uploaded file is validated
if($wait) {

  do {

    $fileStatus = (& $PSScriptRoot\loadtest-get-files.ps1 -apiEndpoint $apiEndpoint `
                            -loadTestId $loadTestId `
                            -fileId $($result.fileName) `
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
