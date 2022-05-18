param (
    [string] $DatabaseMappingFilePath,

    [string] $CrossUsername,
    [securestring] $CrossPassword,
    [string] $AdminUsername,
    [securestring] $AdminPassword
)

$databaseMapping = Get-Content $DatabaseMappingFilePath | ConvertFrom-Json

$i = 0;
$sid = "";
foreach ($server in $databaseMapping) 
{
  Write-Host "Processing server $($server.serverName):"
  #
  # Following queries need to be run against the master database on each server.
  #
  $masterConnectionString = "Server=tcp:$($server.serverName),1433;Initial Catalog=master;Persist Security Info=False;User ID=$($AdminUsername);Password=$(ConvertFrom-SecureString $AdminPassword -AsPlainText);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

  # The first server contains the "parent" login and we get the SID from there.
  if ($i -eq 0) {
    Write-Host "   Creating $($CrossUsername) login..."
    Invoke-Sqlcmd -Query "CREATE LOGIN $($CrossUsername) WITH PASSWORD = '$($CrossPassword)'" -ConnectionString $masterConnectionString `
        
    $sid = (Invoke-Sqlcmd -Query "SELECT convert(VARCHAR(172), sid, 1) AS sid FROM sys.sql_logins WHERE NAME = '$($CrossUsername)'" -ConnectionString $masterConnectionString).sid
  }
  # For secondary servers, we create "child" logins using the SID from primary.
  else {
    Write-Host "   Creating $($CrossUsername) login with SID..."
    Invoke-Sqlcmd -Query "CREATE LOGIN $($CrossUsername) WITH PASSWORD = '$($CrossPassword)', sid=$($sid)" -ConnectionString $masterConnectionString `
  }

  #
  # Following queries need to be run against the writeable database on each server.
  #
  $writeabledbConnectionString = "Server=tcp:$($server.serverName),1433;Initial Catalog=$($server.writeableDatabaseName);Persist Security Info=False;User ID=$($AdminUsername);Password=$(ConvertFrom-SecureString $AdminPassword -AsPlainText);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

  # Create the cross-db user and assign db_owner role
  Write-Host "   Creating $($CrossUsername) user..."
  Invoke-Sqlcmd -Query "CREATE USER $($CrossUsername) FROM LOGIN $($CrossUsername)" -ConnectionString $writeabledbConnectionString `

  Write-Host "   Assigning role..."
  Invoke-Sqlcmd -Query "EXEC sp_addRoleMember 'db_owner', '$($CrossUsername)'" -ConnectionString $writeabledbConnectionString `

  Write-Host "   Creating master key and scoped credential..."
  Invoke-Sqlcmd -Query "CREATE MASTER KEY; CREATE DATABASE SCOPED CREDENTIAL CrossDbCred WITH IDENTITY = '$($CrossUsername)', SECRET = '$($CrossPassword)';" -ConnectionString $writeabledbConnectionString `

  Write-Host "   Done."
  $i++
}

