$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

$loadTestId = "5899bda7-5d7d-4faf-9a5a-7020105b80c6"

. ./loadtest-delete.ps1 `
    -loadTestId "$loadTestId" `
    -apiVersion "$apiVersion" `
    -apiEndpoint "$apiEndpoint"
