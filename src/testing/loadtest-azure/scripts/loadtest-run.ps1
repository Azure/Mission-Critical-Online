# loadtest-run.ps1 | Execute a load test run
param
(
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # optional - load test data plane api version
  [string] $apiVersion = "2023-04-01-preview",

  # Load Test run displayname
  [Parameter(Mandatory=$true)]
  [string] $testRunName,

  # Load test run description
  [string] $testRunDescription,
  
  # optional - expose outputs as pipeline variables
  [bool] $pipeline = $false
)

. "$PSScriptRoot/common.ps1"

function GetTestRunBody {
    param
    (
        [string] $testId,
        [string] $testRunName,
        [string] $description
    )

    $result = @"
    {
        "testId": "$testId",
        "displayName": "$testRunName",
        "description": "$testRunDescription"
    }
"@

    return $result
}

$testRunId = (New-Guid).toString()
$urlRoot = "https://{0}/test-runs/{1}"  -f $apiEndpoint,$testRunId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Prep load test run body
$testRunData = GetTestRunBody `
    -testId $loadTestId `
    -testRunName $testRunName `
    -testRunDescription $testRunDescription

# Following is to get Invoke-RestMethod to work
$url = $urlRoot + "?api-version=" + $apiVersion

$header = @{
    'Content-Type'='application/merge-patch+json'
}

# Secure string to use access token with Invoke-RestMethod in Powershell
$accessTokenSecure = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

$result = Invoke-RestMethod `
    -Uri $url `
    -Method PATCH `
    -Authentication Bearer `
    -Token $accessTokenSecure `
    -Body $testRunData `
    -Headers $header `
    -Verbose:$verbose

echo $result

# Outputs and exports for pipeline usage
if($pipeline) {
    $testRunId = ($result).testRunId
    echo "##vso[task.setvariable variable=testRunId]$testRunId" # contains the testRunId for in-pipeline usage
  }

Remove-Item $accessTokenFileName
