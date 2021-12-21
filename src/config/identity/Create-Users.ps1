# Run in PowerShell with the Microsoft.Graph PowerShell module installed.
# Install-Module Microsoft.Graph


#
# Create test users defined in a JSON file.
# Requires Connect-MgGraph with the right B2C Tenant (see wrapper below).
#
function Import-Users {
  [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
  param (
    $UsersFilePath = "users.json",
    $B2CTenantName # B2C tenant name, without '.onmicrosoft.com'
  )

  $B2CTenantId = "$($B2CTenantName).onmicrosoft.com"

  # Getting the right GameMaster extension property name for this tenant.
  # It contains AppId (without -) of the b2c-extensions-app for this particular tenant.
  #
  # extension_<extension app ID>_GameMaster
  $gameMasterExtensionProp = "extension_$((Get-MgApplication | Where-Object { $_.DisplayName.StartsWith("b2c-extensions-app") }).AppId.Replace('-', ''))_GameMaster";

  $usersFromJson = Get-Content $UsersFilePath | ConvertFrom-Json

  foreach ($user in $usersFromJson.users) {
    $passwordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
    $user | Add-Member -NotePropertyName password -NotePropertyValue (Get-RandomPassword -length 14) # generate a random password
    $passwordProfile.Password = $user.password
    $passwordProfile.ForceChangePasswordNextSignIn = $false

    $identity = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphObjectIdentity
    $identity.SignInType = "emailAddress"
    $identity.Issuer = $B2CTenantId
    $identity.IssuerAssignedId = $user.email

    $extension = @{
      $gameMasterExtensionProp = $user.gameMaster
    }

    New-MgUser -DisplayName $user.displayName `
      -AccountEnabled `
      -Identities $identity `
      -PasswordProfile $PasswordProfile `
      -CreationType LocalAccount `
      -AdditionalProperties $extension | Out-Null

    Write-Host "*** Created user: $($user.email) Password: $($user.password)"
  }

  return $usersFromJson.users | Select email, password, gameMaster # The display name is not needed anywhere later so we filter it out
}

# Source: https://arminreiter.com/2021/07/3-ways-to-generate-passwords-in-powershell/
function Get-RandomPassword {
  param (
      [Parameter(Mandatory)]
      [int] $length
  )
  $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{]+-[*=@:)}$^%;(_!#?>/|.'.ToCharArray()
  $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $bytes = New-Object byte[]($length)

  $rng.GetBytes($bytes)

  $result = New-Object char[]($length)

  for ($i = 0 ; $i -lt $length ; $i++) {
      $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
  }

  return (-join $result)
}

# Wrapper for Import-Users which can be invoked separately - handles authentication.
function Create-Users {
  param (
    $UsersFilePath = "users.json",
    $B2CTenantName # B2C tenant name, without '.onmicrosoft.com'
  )

  $B2CTenantId = "$($B2CTenantName).onmicrosoft.com"

  # Interactive login, so that we don't have to create a separate service principal and handle secrets.
  # Make sure that the user has administrative permissions.
  Connect-MgGraph -TenantId $B2CTenantId -Scopes "User.ReadWrite.All Application.Read.All"

  return Import-Users `
    -UsersFilePath $UsersFilePath `
    -B2CTenantName $B2CTenantName
}