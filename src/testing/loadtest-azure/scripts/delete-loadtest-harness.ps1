$resourceGroupName = "pzmaltapp4-rg"
$loadTestName = "t4"
$loadTestId = "t4"

. ./delete-loadtest.ps1 -resourceGroupName "$resourceGroupName" `
  -loadTestName "$loadTestName" -loadTestId "$loadTestId" `
