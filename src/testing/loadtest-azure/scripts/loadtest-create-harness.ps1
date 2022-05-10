# loadtest-create-harness.ps1
$engineInstances = 3
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

. ./loadtest-create.ps1 `
    -engineInstances "$engineInstances" `
    -apiEndpoint "$apiEndpoint" `
    -verbose:$true
