#
# Cleans up stale resources for a give deployment (i.e. resource prefix)
# These usually occur when a deployment is manually deleted and not through the proper CI/CD pipeline
#
# Requires Azure CLI being installed and authenticated
#

function Remove-SavedLogAnalyticsQueries {
    [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
    param (
      $resourcePrefix = "ace2e122e"
    )

    Write-Host "Using Azure Account:"
    az account show

    # List all Log Analytics Workspaces by a given Prefix tag
    $laWorkspaces = az monitor log-analytics workspace list --query "[?tags.Prefix == '$resourcePrefix']" | ConvertFrom-Json

    foreach($workspace in $laWorkspaces)
    {
      Write-Host "*** Looking for saved searches in workspace $($workspace.Name) in category 'HealthModel'"

      # List all saved searches in the workspace of category "HealthModel" (those are our saved queries)
      $savedSearches = az monitor log-analytics workspace saved-search list --resource-group $workspace.resourceGroup --workspace-name $workspace.name --query "value[?category=='HealthModel']" | ConvertFrom-Json

      foreach($search in $savedSearches)
      {
        Write-Host "Deleting saved search: $($search.name)"
        az monitor log-analytics workspace saved-search delete --resource-group $workspace.resourceGroup --workspace-name $workspace.name --name $search.name --yes
      }
    }
}

function Remove-DiagnosticSettings {
  [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
  param (
    $resourcePrefix = "ace2e122e"
  )

  Write-Host "Using Azure Account:"
  az account show

  # List all resources for a given Prefix tag
  $allResources = az resource list --tag Prefix=$resourcePrefix | ConvertFrom-Json

  foreach($resource in $allResources)
  {
    Write-Host "*** Looking for diagnostic settings in resource $($resource.Name)"

    # List all diagnostic settings for a given resource
    $diagnosticSettings = $(az monitor diagnostic-settings list --resource $resource.Id | ConvertFrom-Json).value

    foreach($setting in $diagnosticSettings)
    {
      Write-Host "Deleting diagnostic setting: $($setting.name)"
      az monitor diagnostic-settings delete --resource $resource.Id --name $setting.name
    }
  }
}
