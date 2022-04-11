$resourceGroupName = "aoint-azloadtest-rg"
$loadTestName = "aoint-azloadtest"
$loadTestId = "e02b0fd9-51ff-410b-b279-0d762fde9899"
$testRunName = "09f8e7ae-3c1b-4727-b47a-ba8f8f23cdd6"
$testRunDescription = "$testRunName Description"
$testRunVUsers = 10

. ./run-loadtest.ps1 -resourceGroupName "$resourceGroupName" `
    -loadTestName "$loadTestName" -loadTestId "$loadTestId" `
    -testRunName "$testRunName" -testRunDescription "$testRunDescription" `
    -testRunVUsers $testRunVUsers  -pipeline $true
