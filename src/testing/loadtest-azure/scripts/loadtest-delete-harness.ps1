# loadtest-delete-harness.ps1
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "<load-test-id>"

. ./loadtest-delete.ps1 `
    -loadTestId "$loadTestId" `
    -apiEndpoint "$apiEndpoint"
