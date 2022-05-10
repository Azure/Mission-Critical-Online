# loadtest-get-run-harness.ps1
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$testRunId = "<load-test-run-id>"

. ./loadtest-get-run.ps1 `
        -apiEndpoint "$apiEndpoint" `
        -testRunId "$testRunId" `
        -verbose:$true
