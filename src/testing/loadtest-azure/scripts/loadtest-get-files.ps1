# loadtest-get-files.ps1 | List all files uploaded to a load test
param
(
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2023-04-01-preview",

  # optional - request an individual file via its fileId
  [string] $fileId,

  # optional - keep access token when used embedded
  [bool] $keepToken = $false
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://{0}/tests/{1}/files" -f $apiEndpoint, $loadTestId

if ($fileId) {
  $urlRoot = "{0}/{1}" -f $urlRoot,$fileId
}

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version=$apiVersion `
  $verbose --output json | convertFrom-Json

if (!$keepToken) {
  # delete accessToken when $keepToken is set to $false (default)
  Remove-Item $accessTokenFileName
}
