# add-loadtest-components-harness.ps1
# Testfile with dummy parameters to test appcomponents-add-to-loadtest.ps1
$apiVersion = "2021-07-01-preview"
$apiEndpoint = "af292971-237a-40f7-8d1f-fd16d95066a3.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "0fa029c0-927a-46cc-aea0-883a9e1c4ae8"

# Execute appcomponents-add-to-loadtest.ps1
. ./appcomponents-add-to-loadtest.ps1 `
    -loadTestId "$loadTestId" `
    -apiVersion "$apiVersion" `
    -apiEndpoint "$apiEndpoint" `
    -resourceName "afe2e1594-uksouth-aks" `
    -resourceType "Microsoft.ContainerService/ManagedClusters" `
    -resourceGroup "afe2e1594-stamp-uksouth-rg" `
    -resourceId "/subscriptions/cb8d2bb0-ed2c-44e5-a01b-cde33c0320a4/resourcegroups/afe2e1594-stamp-uksouth-rg/providers/Microsoft.ContainerService/managedClusters/afe2e1594-uksouth-aks" `
    -subscriptionId "cb8d2bb0-ed2c-44e5-a01b-cde33c0320a4"
