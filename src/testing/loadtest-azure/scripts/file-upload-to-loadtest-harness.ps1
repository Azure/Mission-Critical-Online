$resourceGroupName = "aoint-azloadtest-rg"
$loadTestName = "aoint-azloadtest"
$loadTestId = "bac7393b-1988-4753-854d-35f51447b4ce
"
#$testFileName = "../../../config/loadtest-azure/player-test.jmx"
$testFileName = "../../../config/identity/generated-users.csv"
$testFileId = ""

. "$PSScriptRoot/config.ps1"

. ./file-upload-to-loadtest.ps1 -resourceGroupName "$resourceGroupName" `
                                -loadTestName "$loadTestName" -loadTestId "$loadTestId" `
                                -testFileName "$testFileName" -testFileId "$testFileId"
