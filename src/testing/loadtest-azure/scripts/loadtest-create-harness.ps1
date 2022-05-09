$loadTestDescription = "" # empty to set it to the ID
$engineInstances = 3
$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

. ./loadtest-create.ps1 `
  -loadTestDescription "$loadTestDescription" `
  -engineInstances "$engineInstances" `
  -apiVersion "$apiVersion" `
  -apiEndpoint "$apiEndpoint" -verbose:$true
