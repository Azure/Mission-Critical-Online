

function Remove-SavesLogAnalyticsQueries {
    [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
    param (
      $resourcePrefix = "ace2e122e"
    )

    $laWorkspaces = az monitor log-analytics workspace list --query "[?tags.Prefix == '$resourcePrefix']" | ConvertFrom-Json

    foreach($workspace in $laWorkspaces)
    {
      Write-Host "*** Looking for saved searches in workspace $($workspace.Name) in category 'HealthModel'"

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

  $allResources = az resource list --tag Prefix=$resourcePrefix | ConvertFrom-Json

  foreach($resource in $allResources)
  {
    Write-Host "*** Looking for diagnostic settings in resource $($resource.Name)"

    $diagnosticSettings = az monitor diagnostic-settings list --resource $resource.Id | ConvertFrom-Json
    foreach($setting in $diagnosticSettings)
    {
      Write-Host "Deleting diagnostic setting: $($setting.name)"
      az monitor diagnostic-settings delete --resource $resource.Id --name $setting.name --yes
    }
  }
}