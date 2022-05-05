$apiVersion = "2021-07-01-preview"
$apiEndpoint = "https://5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

$loadTestId = "2a0627f0-546b-4527-a6e9-a34951f15837"

. ./delete-loadtest.ps1 `
    -loadTestId "$loadTestId" `
    -apiVersion "$apiVersion" `
    -apiEndpoint "$apiEndpoint"
