param(
  $mode, # "stamp" or "global"
  $smokeUser,
  $smokePassword,
  $b2cTenantName,
  $b2cUIClientID,
  $b2cRopcPolicyName,
  $smokeTestRetryCount,
  $smokeTestRetryWaitSeconds
)

# -----------
# Load helper functions.
# -----------
. $env:SYSTEM_DEFAULTWORKINGDIRECTORY/.ado/scripts/Invoke-WebRequestWithRetry.ps1
. $env:SYSTEM_DEFAULTWORKINGDIRECTORY/.ado/scripts/Decode-JWT.ps1

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

# get access token for testing user
$params = "?client_id=$b2cUIClientID" `
  + "&username=$smokeUser" `
  + "&password=$smokePassword" `
  + "&grant_type=password" `
  + "&tenant=$b2cTenantName.onmicrosoft.com" `
  + "&scope=https://$b2cTenantName.onmicrosoft.com/$b2cUIClientID/Games.Access"

$b2cUrl = "https://$b2cTenantName.b2clogin.com/$b2cTenantName.onmicrosoft.com/$b2cRopcPolicyName/oauth2/v2.0/token"
Write-Output "*** Getting access token from Azure AD B2C at $b2cUrl"
$res = Invoke-WebRequest -Uri "$($b2cUrl)?$params" -Method POST
$accessToken = ($res.Content | ConvertFrom-Json).access_token

# Parse the JWT access token so we can get the user OID
$decodedJwt = ConvertFrom-JWTtoken -token $accessToken

Write-Output "Decoded user OID: $($decodedJwt.oid)"

# List of all gestures for random picking
$gestures = "rock", "paper", "scissors", "lizard", "spock", "ferrari"

# request body needs to be a valid object expected by the API - keep up to date when the contract changes
$new_game_result_body = @{
  "player1Gesture" = @{
    "playerId" = "$($decodedJwt.oid)"
    "gesture" = "$(Get-Random -InputObject $gestures)"
  }
  "player2Gesture"= @{
    "playerId" = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"    # this is the fixed GUID of the AI player
    "gesture" = "$(Get-Random -InputObject $gestures)"
  }
  "gameDate" = (Get-Date -AsUtc).ToString("o")
} | ConvertTo-JSON

$ai_game_body = "$(Get-Random -InputObject $gestures)" | ConvertTo-JSON


# list of targets to test - either all stamps, or one global endpoint
$targets = @()

if ($mode -eq "stamp") {
  # setting header with X-Azure-FDID for HTTP-based smoke tests (required to access the individual stamps directly, bypassing Front Door)
  $header = @{
    "X-Azure-FDID"="$frontdoorHeaderId"
    "Authorization"="Bearer $accessToken"
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
    "Authorization"="Bearer $accessToken"
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

  $postGameUrl = "https://$targetFqdn/api/1.0/game"
  Write-Output "*** Call - Create new game result ($mode)"

  $responsePostGame = Invoke-WebRequestWithRetry -Uri $postGameUrl -Method 'POST' -Headers $header -Body $new_game_result_body -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds -ExpectedResponseCode 202

  Write-Output "*** Sleeping for 10 seconds to give the system time to create the game result"
  Start-Sleep 10

  # The 202-response to POST new game result contains in the 'Location' header the URL under which the new game result will be accessible
  $gameUrl = $responsePostGame.Headers['Location'][0]

  if ($mode -eq "stamp") {
    # The Location header contains the global FQDN of the Front Door entry point. For the the individual cluster, we need to change the URL
    $gameUrl = $gameUrl -replace $frontdoorFqdn,$targetFqdn
  }

  Write-Output "*** Call - Get newly created game result ($mode)"
  Invoke-WebRequestWithRetry -Uri $gameUrl -Method 'GET' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  $playAiGameUrl = "https://$targetFqdn/api/1.0/game/ai"
  Write-Output "*** Call - Play a game against the AI ($mode)"
  Invoke-WebRequestWithRetry -Uri $playAiGameUrl -Method 'POST' -Headers $header -Body $ai_game_body -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds -ExpectedResponseCode 202

  $myPlayerStatsUrl = "https://$targetFqdn/api/1.0/player/me"
  Write-Output "*** Call - Show Stats for current user ($mode)"
  Invoke-WebRequestWithRetry -Uri $myPlayerStatsUrl -Method 'get' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  $myGamesUrl = "https://$targetFqdn/api/1.0/player/me/games"
  Write-Output "*** Call - List game results for current user ($mode)"
  Invoke-WebRequestWithRetry -Uri $myGamesUrl -Method 'get' -Headers $header -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  Write-Output "*** Call - UI app for $mode"
  $responseUi = Invoke-WebRequestWithRetry -Uri https://$targetUiFqdn -Method 'GET' -MaximumRetryCount $smokeTestRetryCount -RetryWaitSeconds $smokeTestRetryWaitSeconds

  if (!$responseUi.Content.Contains("<title>AlwaysOn Game</title>")) # Check in the HTML content of the response for a known string (the page title in this case)
  {
    throw "*** Web UI for $targetUiFqdn doesn't contain the expected site title."
  }
}