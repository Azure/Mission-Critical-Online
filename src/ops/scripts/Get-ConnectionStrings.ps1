# TODO:
# [ ] Stamp storage connection string
# [ ] Global storage connection string
# [ ] Application insights instrumentation key

$branch = Read-Host "Branch name"

Write-Host "Getting list of EH namespaces..."
$namespaces = $(az eventhubs namespace list --query "[?tags.Branch=='$($branch)'].{name:name,resourceGroup:resourceGroup,branch:tags.Branch,prefix:tags.Prefix}") | ConvertFrom-Json

# TODO: Cover situation when namespaces has multiple results - pick which one to use.

Write-Host "Branch `"$branch`" is associated with environment `"$($namespaces.prefix)`"."

Write-Host "Getting the sender connection string..."
$senderConnectionString = $(az eventhubs eventhub authorization-rule keys list --resource-group "$($namespaces.resourceGroup)" --namespace-name "$($namespaces.name)" --eventhub-name "backendqueue-eh" --name "frontendsender" --query "primaryConnectionString")

Write-Host "Getting the reader connection string..."
$readerConnectionString = $(az eventhubs eventhub authorization-rule keys list --resource-group "$($namespaces.resourceGroup)" --namespace-name "$($namespaces.name)" --eventhub-name "backendqueue-eh" --name "backendreader" --query "primaryConnectionString")

$res = @{
    "FRONTEND_SENDEREVENTHUBCONNECTIONSTRING" = $senderConnectionString.Replace('"', '')
    "BACKEND_READEREVENTHUBCONNECTIONSTRING" = $readerConnectionString.Replace('"', '')
}

$res | ConvertTo-Json
