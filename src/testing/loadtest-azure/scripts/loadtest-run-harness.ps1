# loadtest-run-harness.ps1
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "<load-test-id>"
$testRunName = "<load-test-run-id>"
$testRunDescription = "$testRunName Description"
$testRunVUsers = 10

. ./loadtest-run.ps1 `
    -apiEndpoint $apiEndpoint `
    -loadTestId "$loadTestId" `
    -testRunName "$testRunName" `
    -testRunDescription "$testRunDescription" `
    -testRunVUsers $testRunVUsers `
    -pipeline $true `
    -verbose:$true
