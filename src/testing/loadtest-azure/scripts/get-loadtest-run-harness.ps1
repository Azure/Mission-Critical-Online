$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$testRunId = "9078bcc2-d127-48b8-ab1b-e9980475bb21"

. ./get-loadtest-run.ps1 `
        -apiEndpoint "$apiEndpoint" `
        -apiVersion "$apiVersion" `
        -testRunId "$testRunId"
