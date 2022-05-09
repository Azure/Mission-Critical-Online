$apiVersion = "2021-07-01-preview"
$apiEndpoint = "5e241573-3a5f-4361-bf53-1ae7bde73cb7.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created

$loadTestId = "6ac85c38-e783-4ec7-94cc-db6c68fef1aa"

$testRunName = "09f8e7ae-3c1b-4727-b47a-ba8f8f23cdd6"
$testRunDescription = "$testRunName Description"
$testRunVUsers = 10

. ./loadtest-run.ps1 `
    -apiEndpoint $apiEndpoint `
    -apiVersion $apiVersion `
    -loadTestId "$loadTestId" `
    -testRunName "$testRunName" `
    -testRunDescription "$testRunDescription" `
    -testRunVUsers $testRunVUsers `
    -pipeline $true -verbose:$true
