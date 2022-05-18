param (
    [string] $TemplateFilePath = "./data-sources.sql.template",
    [string] $DatabaseMappingFilePath,
    [string] $OutputDirectory = "./mapping"
)

# Install-Module SqlServer

$template = Get-Content $TemplateFilePath
$dataSourceMappings = Get-Content $DatabaseMappingFilePath | ConvertFrom-Json

$dataSourceMappings

# Delete generated mappings if present.
if (Test-Path $OutputDirectory) {
  Write-Host "Cleaning the output directory..."
  Remove-Item $OutputDirectory -Recurse
}

New-Item -ItemType Directory $OutputDirectory -Force

foreach ($server in $dataSourceMappings) {
  $ds = @()
  $selects = @()
  $selectsRatings = @()
  $selectsComments = @()
  $i = 1

  foreach ($mapping in $server.dataSources) {
    $ds += $template `
      -Replace "{{EXTERNAL_DATA_SOURCE_NAME}}", $mapping.dataSourceName `
      -Replace "{{SERVER_NAME}}", $server.serverName `
      -Replace "{{DATABASE_NAME}}", $mapping.databaseName `
      -Replace "{{CATALOGITEMS_EXTERNAL_TABLE_NAME}}", $mapping.catalogItemsExternalTableName `
      -Replace "{{RATINGS_EXTERNAL_TABLE_NAME}}", $mapping.ratingsExternalTableName `
      -Replace "{{COMMENTS_EXTERNAL_TABLE_NAME}}", $mapping.commentsExternalTableName

    $selects += "SELECT * FROM [ao].[$($mapping.catalogItemsExternalTableName)]`n"
    if ($i -lt $server.dataSources.Length) { $selects += "UNION ALL`n" } # last one will not have UNION

    $selectsRatings += "SELECT * FROM [ao].[$($mapping.ratingsExternalTableName)]`n"
    if ($i -lt $server.dataSources.Length) { $selectsRatings += "UNION ALL`n" } # last one will not have UNION

    $selectsComments += "SELECT * FROM [ao].[$($mapping.commentsExternalTableName)]`n"
    if ($i -lt $server.dataSources.Length) { $selectsComments += "UNION ALL`n" } # last one will not have UNION

    $i++
  }
  
  $ds += "`nCREATE VIEW [ao].[AllCatalogItems] AS`n" `
       + "SELECT * FROM [ao].[CatalogItems]`n" `
       + "UNION ALL`n" `
       + $selects `
       + "GO`n"

  $ds += "`nCREATE VIEW [ao].[AllRatings] AS`n" `
       + "SELECT * FROM [ao].[Ratings]`n" `
       + "UNION ALL`n" `
       + $selectsRatings `
       + "GO`n"

  $ds += "`nCREATE VIEW [ao].[AllComments] AS`n" `
       + "SELECT * FROM [ao].[Comments]`n" `
       + "UNION ALL`n" `
       + $selectsComments `
       + "GO`n"

  $ds | Out-File "$($OutputDirectory)/$($server.serverName).sql"

  # execute here straigt away?
}