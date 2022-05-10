# add-loadtest-components-harness.ps1
# Testfile with dummy parameters to test appcomponents-add-to-loadtest.ps1
$apiEndpoint = "af292971-237a-40f7-8d1f-fd16d95066a3.neu.cnt-prod.loadtesting.azure.com" #needs to be updated... will be returned when resource is created
$loadTestId = "89fadde5-49f0-4eb4-b835-6a14e3134eda"

# Execute appcomponents-add-to-loadtest.ps1
. ./appcomponents-add-to-loadtest.ps1 `
    -loadTestId "$loadTestId" `
    -apiEndpoint "$apiEndpoint" `
    -resourceId "/subscriptions/cb8d2bb0-ed2c-44e5-a01b-cde33c0320a4/resourcegroups/afe2e1594-stamp-uksouth-rg/providers/Microsoft.ContainerService/managedClusters/afe2e1594-uksouth-aks" 
