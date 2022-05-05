#$resourceGroupName = "aoint-azloadtest-rg"
$loadTestName = "aoint-azloadtest"
$loadTestId = "" # empty to generate a new one
$loadTestDescription = "$loadTestName" + " Description"
$engineSize = "m"
$engineInstances = 3

. "$PSScriptRoot/config.ps1"

. ./create-loadtest.ps1 -loadTestName "$loadTestName" -loadTestId "$loadTestId" `
  -loadTestDescription "$loadTestDescription" -engineSize "$engineSize" `
  -engineInstances "$engineInstances" # -resourceGroupName "$resourceGroupName" 
