# loadtest-delete.ps1 | Delete a load test
param
(
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2022-06-01-preview"
)

if (!$loadTestId) {
  throw "ERROR - Parameter loadTestId is required and cannot be empty."
}

. ./common.ps1

$urlRoot = "https://{0}/loadtests/{1}" -f $apiEndpoint,$loadTestId

az rest --url $urlRoot `
  --method DELETE `
  --skip-authorization-header `
  --headers "$accessTokenHeader" `
  --url-parameters testId="$loadTestId" api-version="$apiVersion" `
  $verbose
