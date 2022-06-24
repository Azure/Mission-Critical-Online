# loadtest-run.ps1 | Execute a load test run
param
(
  # Load Test Id
  [Parameter(Mandatory=$true)]
  [string] $loadTestId,
  
  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # Load Test data plane api version
  [string] $apiVersion = "2021-07-01-preview",

  # Load Test run displayname
  [Parameter(Mandatory=$true)]
  [string] $testRunName,

  # Load test run description
  [string] $testRunDescription,
  [int] $testRunVUsers = 1,
  [bool]$pipeline = $False 
)

. "$PSScriptRoot/common.ps1"

function GetTestRunBody {
    param
    (
        [string] $testId,
        [string] $testRunName,
        [string] $description,
        [string] $testRunId,
        [int] $vusers
    )

    $result = @"
    {
        "testId": "$testId",
        "testRunId": "$testRunId",
        "displayName": "$testRunName",
        "description": "$testRunDescription",
        "vusers": $vusers
    }
"@

    return $result
}

$testRunId = (New-Guid).toString()
$urlRoot = "https://" + $apiEndpoint + "/testruns/" + $testRunId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Prep load test run body
$testRunData = GetTestRunBody `
    -testId $loadTestId `
    -testRunName $testRunName `
    -testRunDescription $testRunDescription `
    -testRunId $testRunId `
    -vusers $testRunVUsers

# Following is to get Invoke-RestMethod to work
$url = $urlRoot + "?api-version=" + $apiVersion # + "&tenantId=" + $tenantId

$header = @{
    'Content-Type'='application/merge-patch+json'
    'testRunId'="$testRunId"
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
