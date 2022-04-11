$resourceGroupName = "aoint-azloadtest-rg"
$loadTestName = "aoint-azloadtest"
$testRunId = "09f8e7ae-3c1b-4727-b47a-ba8f8f23cdd6"

. ./get-loadtest-run.ps1 -resourceGroupName "$resourceGroupName" -loadTestName "$loadTestName" -testRunId "$testRunId"
