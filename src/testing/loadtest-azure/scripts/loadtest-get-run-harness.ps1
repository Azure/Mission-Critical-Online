$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$testRunId = "67207147-b99a-4dba-b653-79cadead7e42"

. ./loadtest-get-run.ps1 `
        -apiEndpoint "$apiEndpoint" `
        -apiVersion "$apiVersion" `
        -testRunId "$testRunId" `
        -verbose:$true
