# Run in PowerShell with the Microsoft.Graph PowerShell module installed.
# Install-Module Microsoft.Graph

function Initialize-NewUsersBulk {
  [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
  param (
    $numberOfUsers = 1000,
    $userEmailBase = "@alwayson.demo", # This does not have to be a real domain. You can even leave this as is for load testing purposes.
    $password,
    $B2CTenantName # B2C tenant name, without '.onmicrosoft.com'
  )

  $B2CTenantId = "$($B2CTenantName).onmicrosoft.com"

  $userNameBase = "loadtester-"
  $displayNameBase = "Load Tester "
  $outputFileName = "test-users-$($tenantId.Split(".")[0]).csv" # add the name of the tenant to the file name

  # --------------------------

  # Interactive login, so that we don't have to create a separate service principal and handle secrets.
  # Make sure that the user has administrative permissions.
  Connect-MgGraph -TenantId $B2CTenantId -Scopes "User.ReadWrite.All Application.Read.All"

  for ($i = 0; $i -lt $numberOfUsers; $i++) {
    $username = "$($userNameBase)$i"
    $email = "$username$userEmailBase"
    $displayName = "$displayNameBase$i"

    Write-Output "Creating new user $username - Display Name: $displayName - Email: $email"

    $passwordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
    $passwordProfile.Password = $password
    $passwordProfile.ForceChangePasswordNextSignIn = $false

    $identity = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphObjectIdentity
    $identity.SignInType = "emailAddress"
    $identity.Issuer = $tenantId
    $identity.IssuerAssignedId = $email

    $user = New-MgUser -DisplayName $displayName `
      -AccountEnabled `
      -Identities $identity `
      -PasswordProfile $PasswordProfile `
      -CreationType LocalAccount

    # Write user list as CSV file:
    # email,id
    Add-Content -Path $outputFileName -Value "$email,$($user.Id)"
  }
}