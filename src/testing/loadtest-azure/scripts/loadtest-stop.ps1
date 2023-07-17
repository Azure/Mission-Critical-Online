# loadtest-delete.ps1 | Delete a load test
param
(
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2023-04-01-preview"
)

if (!$loadTestId) {
  throw "ERROR - Parameter loadTestId is required and cannot be empty."
}

. ./common.ps1

$urlRoot = "https://{0}/tests/{1}" -f $apiEndpoint,$loadTestId

az rest --url $urlRoot `
  --method DELETE `
  --skip-authorization-header `
  --headers "$accessTokenHeader" `
  --url-parameters testId="$loadTestId" api-version="$apiVersion" `
  $verbose
