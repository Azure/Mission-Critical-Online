$tenantId = az account show --output tsv --query 'tenantId'
$subscriptionId = az account show --output tsv --query 'id'

$accessToken = az account get-access-token `
                        --output tsv `
                        --subscription $subscriptionId `
                        --query 'accessToken' `
                        --resource https://loadtest.azure-dev.com
$accessTokenHeader = "Authorization=Bearer {0}" -f $accessToken

# Write access token to file as otherwise HTTP request too long to use az rest in Powershell
$accessTokenFileName = "./accesstoken.txt"
$accessTokenHeader | Out-File -FilePath $accessTokenFileName -Force