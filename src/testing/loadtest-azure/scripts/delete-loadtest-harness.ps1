$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

$loadTestId = "df6783e6-9c93-4e47-86c7-be1fcd6ebfda"

. ./delete-loadtest.ps1 `
    -loadTestId "$loadTestId" `
    -apiVersion "$apiVersion" `
    -apiEndpoint "$apiEndpoint"
