function Invoke-WebRequestWithRetry {
  [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
  param (
    $Uri,
    $Method = "GET",
    $Headers,
    $Body = $null,
    $MaximumRetryCount = 5,
    $RetryWaitSeconds,
    $ExpectedResponseCode = 200
  )

  # custom retry loop to handle the situation when Invoke-WebRequest throws an exception without getting HTTP status code
  $isSuccess = $false;
  $retryCount = 0;
  do {
    try {
      Write-Host "[$method] $Uri"
      $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -Body $Body -ContentType "application/json"
      if ($response.StatusCode -ne $ExpectedResponseCode) {
        throw "*** Expecting reponse code $ExpectedResponseCode, was: $($response.StatusCode)"
      }
      $isSuccess = $true
    } catch {
      Write-Host $_; # print the first exception too
      if ($retrycount -ge $MaximumRetryCount) {
        throw "*** Request to $Uri failed the max. number of retries."
      } else {
        $retrycount++
        Write-Warning "*** Request to $Uri failed. Retrying... $retrycount/$MaximumRetryCount"
        Start-Sleep $RetryWaitSeconds
      }
    }
  } while (-not $isSuccess)

  Write-Output $response
}