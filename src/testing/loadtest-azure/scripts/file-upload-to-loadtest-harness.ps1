# file-upload-to-loadtest-harness.ps1
$testFileName = "/path/to/<load-test-definition>.jmx"
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "<load-test-id>"

. ./file-upload-to-loadtest.ps1 -loadTestId "$loadTestId" `
                                -testFileName "$testFileName" `
                                -apiEndpoint "$apiEndpoint" `
                                -verbose:$true
