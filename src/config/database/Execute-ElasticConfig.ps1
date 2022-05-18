param (
  [string] $MappingDirectory = "./mapping",
  [string] $DatabaseMappingFilePath,
  
  [string] $CrossUsername,
  [securestring] $CrossPassword
)

$dataSourceMappings = Get-Content $DatabaseMappingFilePath | ConvertFrom-Json

foreach ($server in $dataSourceMappings) {
  $writeabledbConnectionString = "Server=tcp:$($server.serverName),1433;Initial Catalog=$($server.writeableDatabaseName);Persist Security Info=False;User ID=$($CrossUsername);Password=$(ConvertFrom-SecureString $CrossPassword -AsPlainText);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

  # Run each script against corresponding server.
  Write-Host "Executing $($server.serverName).sql..."
  Invoke-Sqlcmd -InputFile "$($MappingDirectory)/$($server.serverName).sql" -ConnectionString $writeabledbConnectionString
}
