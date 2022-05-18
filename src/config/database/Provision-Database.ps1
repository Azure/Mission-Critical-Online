# These values are provided by the deployment pipeline once SQL Databases are created.
$crossUsername = "CrossDb"
$crossPassword = ConvertTo-SecureString -String "N/A" -AsPlainText -Force
$adminUsername = "master"
$adminPassword = ConvertTo-SecureString -String "N/A" -AsPlainText -Force

$databaseMappingFilePath = "./data-source-mapping.json"
$elasticConfigOutputDir = "./mapping"

#TODO: error handling - what if any of the steps fail

# Logins need to be created first, because external data sources depend on them.
./Create-Logins.ps1 `
    -AdminUsername $adminUsername `
    -AdminPassword $adminPassword `
    -CrossUsername $crossUsername `
    -CrossPassword $crossPassword `
    -DatabaseMappingFilePath $databaseMappingFilePath

# Creates the SQL scripts to configure external tables etc., but doesn't execute anything yet.
./Generate-ElasticConfig.ps1 `
    -DatabaseMappingFilePath $databaseMappingFilePath `
    -OutputDirectory $elasticConfigOutputDir

# Execute each SQL script against the right server & database.
./Execute-ElasticConfig.ps1 `
    -MappingDirectory $elasticConfigOutputDir `
    -DatabaseMappingFilePath $databaseMappingFilePath `
    -CrossUsername $crossUsername `
    -CrossPassword $crossPassword