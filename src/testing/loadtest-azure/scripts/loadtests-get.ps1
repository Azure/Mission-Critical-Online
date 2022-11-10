# loadtests-get.ps1 | List existing load tests
param
(
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # optional - expose outputs as pipeline variables
  [bool] $pipeline = $false

  [int] $maxPageSize
)

. "$PSScriptRoot/common.ps1"

$urlRoot = "https://{0}/loadtests/{1}"  -f $apiEndpoint,$loadTestId

az rest --url $urlRoot `
  --method GET `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) `
  --url-parameters api-version="$apiVersion" maxPageSize=$maxPageSize `
  $verbose

Remove-Item $accessTokenFileName
