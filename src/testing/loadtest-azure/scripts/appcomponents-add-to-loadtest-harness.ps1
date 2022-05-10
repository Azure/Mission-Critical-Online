# add-loadtest-components-harness.ps1
# Testfile with dummy parameters to test appcomponents-add-to-loadtest.ps1
$apiEndpoint = "<load-test-service>.<region>.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "<load-test-id>"

# Execute appcomponents-add-to-loadtest.ps1
. ./appcomponents-add-to-loadtest.ps1 `
    -loadTestId "$loadTestId" `
    -apiEndpoint "$apiEndpoint" `
    -resourceId "/subscriptions/cb8d2bb0-ed2c-44e5-a01b-cde33c0320a4/resourcegroups/afe2e1594-stamp-uksouth-rg/providers/Microsoft.ContainerService/managedClusters/afe2e1594-uksouth-aks" 
