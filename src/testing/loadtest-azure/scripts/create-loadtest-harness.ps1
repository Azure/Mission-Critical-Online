$loadTestId = "" # empty to generate a new one
$loadTestDescription = "" # empty to set it to the ID
$engineInstances = 3
$apiVersion = "2021-07-01-preview"
$apiEndpoint = "https://management.azure.com5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

. ./create-loadtest.ps1 `
  -loadTestId "$loadTestId" `
  -loadTestDescription "$loadTestDescription" `
  -engineInstances "$engineInstances" `
  -apiVersion "$apiVersion" `
  -apiEndpoint "$apiEndpoint"
