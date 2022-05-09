$apiVersion = "2021-07-01-preview"
$apiEndpoint = "af292971-237a-40f7-8d1f-fd16d95066a3.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$maxPageSize = 20

. ./loadtests-get.ps1 -maxPageSize $maxPageSize `
                      -apiEndpoint $apiEndpoint `
                      -apiVersion $apiVersion
