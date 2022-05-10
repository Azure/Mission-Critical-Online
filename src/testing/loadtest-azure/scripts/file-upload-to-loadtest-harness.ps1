# file-upload-to-loadtest-harness.ps1
$loadTestId = "6ac85c38-e783-4ec7-94cc-db6c68fef1aa"
$testFileName = "/mnt/c/git/AlwaysOn-foundational/src/testing/loadtest-azure/scripts/catalogue-test.jmx"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

. ./file-upload-to-loadtest.ps1 -loadTestId "$loadTestId" `
                                -testFileName "$testFileName" `
                                -apiEndpoint "$apiEndpoint" `
                                -verbose:$true
