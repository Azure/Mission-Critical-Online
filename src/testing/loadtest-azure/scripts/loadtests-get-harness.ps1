# loadtests-get-harness.ps1
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$maxPageSize = 20

. ./loadtests-get.ps1 -maxPageSize $maxPageSize `
                      -apiEndpoint $apiEndpoint
