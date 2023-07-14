# loadtest-create.ps1 | Create new load tests in an existing Azure Load Test service instance
param
(
  # Load Test Id - auto-generated when empty
  [string] $loadTestId = (New-Guid).toString(),

  # Load Test Displayname shown in Azure Portal
  [string] $loadTestDisplayName,

  # Load Test Description shown in Azure Portal
  [string] $loadTestDescription,
  
  [Parameter(Mandatory = $true)]
  [string] $loadTestTargetUrl,

  # Number of User threads
  [Parameter(Mandatory = $true)]
  [int] $loadTestUserThreads,

  # Load test run duration (in seconds)
  [Parameter(Mandatory = $true)]
  [int] $loadTestDurationSeconds,

  # Load Test engine instances
  [int] $engineInstances = "1",

  # Load Test data plane endpoint
  [Parameter(Mandatory=$true)]
  [string] $apiEndpoint,

  # parameter to handover a json file with test criteria
  [string] $passFailCriteria,

  # optional - load test data plane api version
  [string] $apiVersion = "2023-04-01-preview",

  # optional - expose outputs as pipeline variables
  [bool] $pipeline = $false
)

# setting loadTestDisplayName to loadTestName when empty
if (!$loadTestDisplayName) {
  $loadTestDisplayName = $loadTestId
}

function GetTestBody {
  param
  (
    [string] $loadTestDisplayName,
    [string] $loadTestDescription,
    [int] $engineInstances
  )

  $result = @"
  {
      "displayName": "$loadTestDisplayName",
      "description": "$loadTestDescription",
      "loadTestConfiguration": {
          "engineInstances": $engineInstances
      },
      "environmentVariables": {
        "target_url": "$loadTestTargetUrl",
        "threads": $loadTestUserThreads,
        "load_duration_seconds": $loadTestDurationSeconds
      },
      "autoStopCriteria": {
        "autoStopEnabled": false, 
        "isAutoStopEnabled": false,
        "errorRate": 90,
        "errorRateTimeWindow": 60
      }
  }
"@

  return $result
}

. "$PSScriptRoot/common.ps1"

# Write test data to file as this avoids request too long as well as
# PS1+az cli quoting issues - see https://github.com/Azure/azure-cli/blob/dev/doc/quoting-issues-with-powershell.md#best-practice-use-file-input-for-json
$testDataFileName = $loadTestId + ".txt"

$body = GetTestBody -loadTestDisplayName $loadTestDisplayName `
            -loadTestDescription $loadTestDescription `
            -engineInstances $engineInstances 

if ($passFailCriteria) {
  Write-Verbose "*** passFailCriteria set to $passFailCriteria"

  if (!(Test-Path $passFailCriteria)) {
    throw "ERROR: $passFailCriteria not found or invalid."
  }

  $content = Get-Content $passFailCriteria | ConvertFrom-JSON

  $jsonBase = $body | ConvertFrom-Json
  $jsonBase | Add-Member -MemberType NoteProperty -Name "passFailCriteria" -Value $content

  $body = $jsonBase | ConvertTo-JSON -Depth 4
}

$body | Out-File $testDataFileName -Encoding utf8

Write-Verbose "*** Test request body"
$body

$urlRoot = "https://{0}/tests/{1}" -f $apiEndpoint, $loadTestId
Write-Verbose "*** Load test service data plane: $urlRoot"

# Create a new load test resource or update existing, if loadTestId already exists
az rest --url $urlRoot `
  --method PATCH `
  --skip-authorization-header `
  --headers ('@' + $accessTokenFileName) "Content-Type=application/merge-patch+json" `
  --url-parameters api-version=$apiVersion `
  --body ('@' + $testDataFileName) `
  --output none $verbose 

if($LastExitCode -ne 0)
{
    throw "*** Error on creating load test instance!"
}

# Outputs and exports for pipeline usage
if($pipeline) {
  echo "##vso[task.setvariable variable=loadTestId]$loadTestId" # contains the loadTestId for in-pipeline usage
}

# Delete the access token and test data files
Remove-Item $accessTokenFileName
Remove-Item $testDataFileName

Write-Verbose "*** Load test $loadTestId successfully created."
