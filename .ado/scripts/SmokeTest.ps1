param(
  $mode, # "stamp" or "global"
  $smokeTestRetryCount,
  $smokeTestRetryWaitSeconds
)

# -----------
# Load helper functions.
# -----------
. $env:SYSTEM_DEFAULTWORKINGDIRECTORY/.ado/scripts/Invoke-WebRequestWithRetry.ps1

# -----------
# Execute smoke tests.
# -----------

if (!("stamp", "global" -eq $mode)) {
  throw "Mode should be either 'stamp' or 'global'."
}

# load json data from downloaded terraform artifacts
$globalInfraDeployOutput = Get-ChildItem $env:PIPELINE_WORKSPACE/terraformOutputGlobalInfra/*.json | Get-Content | ConvertFrom-JSON

$releaseUnitInfraDeployOutput = Get-ChildItem $env:PIPELINE_WORKSPACE/terraformOutputReleaseUnitInfra/*.json | Get-Content | ConvertFrom-JSON

# Azure Front Door Endpoint URI
$frontdoorFqdn = $globalInfraDeployOutput.frontdoor_fqdn.value

# Azure Front Door Header ID
$frontdoorHeaderId = $globalInfraDeployOutput.frontdoor_id_header.value

Write-Output "*******************"
Write-Output "*** SMOKE TESTS ***"
Write-Output "*******************"

# request body needs to be a valid object expected by the API - keep up to date when the contract changes
$post_comment_body = @{
  "authorName" = "Smoke Test Author"
  "text" = "Just a smoke test"
} | ConvertTo-JSON


# list of targets to test - either all stamps, or one global endpoint
$targets = @()

if ($mode -eq "stamp") {
  # setting header with X-Azure-FDID for HTTP-based smoke tests (required to access the individual stamps directly, bypassing Front Door)
  $header = @{
    "X-Azure-FDID"="$frontdoorHeaderId"
    "X-TEST-DATA"="true" # Header to indicate that posted comments and rating are just for test and can be deleted again by the app
  }

  # loop through stamps from pipeline artifact json
  foreach($stamp in $releaseUnitInfraDeployOutput.stamp_properties.value) {
    # from stamp we need:
    # - aks_cluster_ingress_fqdn = endpoint to be called
    # - storage_web_host = ui host

    $props = @{
      # Individual Cluster Endpoint FQDN (from pipeline artifact json)
      ApiEndpointFqdn = $stamp.aks_cluster_ingress_fqdn
      UiEndpointFqdn = $stamp.storage_web_host
    }

    $obj = New-Object PSObject -Property $props
    $targets += $obj
  }
}
else {
  $header = @{
    "X-TEST-DATA"="true"
  }

  $props = @{
    ApiEndpointFqdn = $frontdoorFqdn
    UiEndpointFqdn = $frontdoorFqdn
  }

  $obj = New-Object PSObject -Property $props
  $targets += $obj
}

Write-Output "*** Testing $($targets.Count) targets"

# loop through targets - either multiple stamps or one front door (global)
foreach($target in $targets) {

  # shorthand for easier manipulation in strings
  $targetFqdn = $target.ApiEndpointFqdn
  $targetUiFqdn = $target.UiEndpointFqdn

  Write-Output "*** Testing $mode availability using $targetFqdn"

  # test health endpoints for stamps only
  if ($mode -eq "stamp") {
    $stampHealthUrl = "https://$targetFqdn/health/stamp"
    Write-Output "*** Call - Stamp Health ($mode)"

    # custom retry loop to handle the situation when the SSL certificate is not valid yet and Invoke-WebRequest throws an exception
    Invoke-WebRequestWithRetry -Uri $stampHealthUrl -Method 'GET' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds
  }

  $listCatalogUrl = "https://$targetFqdn/api/1.0/catalogitem"
  Write-Output "*** Call - List Catalog ($mode)"
  $responseListCatalog = Invoke-WebRequestWithRetry -Uri $listCatalogUrl -Method 'get' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds
  $responseListCatalog

  $allItems = $responseListCatalog.Content | ConvertFrom-JSON
  $randomItem = Get-Random $allItems

  $itemUrl = "https://$targetFqdn/api/1.0/catalogitem/$($randomItem.id)"
  Write-Output "*** Call - Get get item ($($randomItem.id)) ($mode)"
  Invoke-WebRequestWithRetry -Uri $itemUrl -Method 'GET' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  $postCommentUrl = "https://$targetFqdn/api/1.0/catalogitem/$($randomItem.id)/comments"
  Write-Output "*** Call - Post new comment to item $($randomItem.id) ($mode)"

  $responsePostComment = Invoke-WebRequestWithRetry -Uri $postCommentUrl -Method 'POST' -Headers $header -Body $post_comment_body -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds -ExpectedResponseCode 202
  $responsePostComment

  Write-Output "*** Sleeping for 10 seconds to give the system time to create the comment"
  Start-Sleep 10

  # The 202-response to POST new comment contains in the 'Location' header the URL under which the new comment will be accessible
  $getCommentUrl = $responsePostComment.Headers['Location'][0]

  if ($mode -eq "stamp") {
    # The Location header contains the global FQDN of the Front Door entry point. For the the individual cluster, we need to change the URL
    $getCommentUrl = $getCommentUrl -replace $frontdoorFqdn,$targetFqdn
  }

  Write-Output "*** Call - Get newly created comment ($mode)"
  Invoke-WebRequestWithRetry -Uri $getCommentUrl -Method 'GET' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  Write-Output "*** Call - UI app for $mode"
  $responseUi = Invoke-WebRequestWithRetry -Uri https://$targetUiFqdn -Method 'GET' -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds
  $responseUi

  if (!$responseUi.Content.Contains("<title>AlwaysOn Catalog</title>")) # Check in the HTML content of the response for a known string (the page title in this case)
  {
    throw "*** Web UI for $targetUiFqdn doesn't contain the expected site title."
  }
}