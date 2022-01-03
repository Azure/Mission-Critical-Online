
#
# Cleans up the terraform state storage account from any stale data
# These usually occur when a deployment is manually deleted and not through the proper CI/CD pipeline which would delete the state file in the end
#
# Requires Azure CLI being installed
#
function Remove-StaleTerraformStateFiles {
    [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
    param (
      $storageAccountName = "aoe2etfstatestore",
      $containerName = "tfstate"
    )

    Write-Host "Using Azure Account:"
    az account show

    # List names of all resource groups
    $resourceGroupNames = az group list --query "[].name" | ConvertFrom-Json

    # List blobs
    $blobs = az storage blob list --account-name $storageAccountName --container-name $containerName | ConvertFrom-Json

    foreach ($blob in $blobs){
        Write-Host "Checking blob $($blob.name)"

        # Format for the blob name is "terraform-<optional part>-<prefix>.state"
        # So we need to extract the prefix

        $blob.name -match "^.+-(?<prefix>.+)\.state" | out-null
        $extractedPrefix = $Matches.prefix
        if(-not $extractedPrefix){
            Write-Host "Skipping blob $($blob.name) as it does not have a prefix"
            continue
        }

        Write-Host "Extracted prefix $extractedPrefix"
        $resourceGroups = $resourceGroupNames | Where-Object { $_.StartsWith($extractedPrefix) }

        if($resourceGroups){
            Write-Host "Found existing resource groups for prefix $extractedPrefix - Not deleting state file"
            continue
        }
        else
        {
            Write-Host "No resource groups found for prefix $extractedPrefix - Deleting state file!"
            az storage blob delete --account-name $storageAccountName --container-name $containerName -n $blob.name
        }
    }

    Write-Host "Finished terraform state cleanup"
}