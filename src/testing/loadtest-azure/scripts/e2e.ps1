. ./common.ps1

# ##########
# General
$resourceGroupName = "afint-azloadtest-rg"
$loadTestName = "t10"
$loadTestId = "" # Leave empty to create a new load test. Provide a GUID to update an existing load test with that name/ID, or create new if no existing load test with that name/ID.
$testFile = "default.jmx"
$testFileId="9b92ed36-cbef-4466-9f23-99eea70341c4"
$maxPageSize = 20
# ##########

# ##########
# Create/update load test
$loadTestDescription = $loadTestName + " Description"
$engineSize = "M"
$engineInstances = 3

# If loadTestId is not empty, and that Id exists, then the existing load test with this name/Id will be updated
Write-Host "Create/update load test resource"
$loadTestId = ./create-loadtest.ps1 -resourceGroupName $resourceGroupName `
    -loadTestName $loadTestName -loadTestId $loadTestId `
    -loadTestDescription $loadTestDescription -engineSize $engineSize `
    -engineInstances $engineInstances
# ##########

# ##########
# Get load test resource
Write-Host "Get load test resources"
./get-loadtests.ps1 -resourceGroupName $resourceGroupName -loadTestName $loadTestName -loadTestId $loadTestId -maxPageSize $maxPageSize
# ##########

# ##########
# Upload jmx file to load test resource
Write-Host "Upload jmx file to load test resource"
./file-upload-to-loadtest.ps1 -resourceGroupName $resourceGroupName -loadTestName $loadTestName -loadTestId $loadTestId -testFileName $testFile -testFileId $testFileId
# ##########

# ##########
# Get load test resource file info
Write-Host "Get test file info"
$filesResult = ./get-loadtest-files.ps1 -resourceGroupName $resourceGroupName -loadTestName $loadTestName -loadTestId $loadTestId -maxPageSize $maxPageSize | ConvertFrom-Json | Select-Object -expand value
$loadTestFileName = $filesResult.filename
$loadTestFileUrl = $filesResult.url
# ##########

# ##########
# Run load test
Write-Host "Run load test"
$testRunName = $loadTestName + "r1"
$testRunDescription = $testRunName + " Description"
$testRunVUsers = 10

. ./run-loadtest.ps1 -resourceGroupName $resourceGroupName `
    -loadTestName $loadTestName -loadTestId $loadTestId `
    -testRunName $testRunName -testRunDescription $testRunDescription `
    -testRunVUsers $testRunVUsers
# ##########
