$tenantId = az account show -o tsv --query 'tenantId'
$subscriptionId = az account show -o tsv --query 'id'

$accessToken = az account get-access-token -o tsv `
                        --subscription $subscriptionId `
                        --query 'accessToken' `
                        --resource https://loadtest.azure-dev.com
$accessTokenHeader = "Authorization=Bearer " + $accessToken

# Write access token to file as otherwise HTTP request too long to use az rest in Powershell
$accessTokenFileName = "./accesstoken.txt"
$accessTokenHeader | Out-File -FilePath $accessTokenFileName -Force

# The data plane API is using self-signed certificates
#$env:ADAL_PYTHON_SSL_NO_VERIFY = '1'
#$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = '1'
