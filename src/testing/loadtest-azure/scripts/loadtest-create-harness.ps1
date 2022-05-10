# loadtest-create-harness.ps1
$engineInstances = 3
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

. ./loadtest-create.ps1 `
    -engineInstances "$engineInstances" `
    -apiEndpoint "$apiEndpoint" `
    -verbose:$true
