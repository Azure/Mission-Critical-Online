# Identity-related support scripts

To simplify tasks related to Azure AD B2C and automate as much as possible, several scripts were developed and can be found in this folder.

## `Create-AzureB2C.ps1`

**What it does?**

End-to-end provisioning of a new Azure AD B2C tenant.

**How to use?**

Use through PowerShell dot-sourcing and then invoke individual functions.

The main function is `Initialize-B2CTenant`:

```powershell
. ./Create-AzureB2C.ps1 # dot-source the main script file
Initialize-B2CTenant -B2CTenantName mynewtenant -ResourceGroupName myrg -Location "Europe" -CountryCode "GB"
```

**Requirements**

* PowerShell Core is supported; Windows, Linux, Mac OS are supported.
* `Microsoft.Graph` PowerShell module has to be installed.
* Azure CLI needs to be installed and authenticated for the owning tenant.

## `Create-ServicePrincipal.ps1`

**What it does?**

Create an application registration within an existing B2C tenant and assign `Application.ReadWrite.All` Microsoft Graph permissions. It's meant to be used to create a service principal for ADO pipelines that modify Redirect URI, but can be modified to other use cases.

The script contains functions to create a self-signed certificate, register application in B2C and update ADO variable groups.

**How to use?**

Use through PowerShell dot-sourcing and then invoke individual functions.

The main function is `Create-ServicePrincipal`:

```powershell
. /Create-ServicePrincipal.ps1
Create-ServicePrincipal -AppName "ADO Graph Client" -TenantId "myb2c.onmicrosoft.com" -AdoOrganization "https://dev.azure.com/myorg" -AdoProjectName "alwaysonapplication" -AdoPAT "mypatvalue" -AdoVariableGroupName "e2e-env-vg"
```

**Requirements**

* PowerShell Core is supported; Windows, Linux, Mac OS are supported.
* `Microsoft.Graph` PowerShell module has to be installed.
* [ADO Personal Access Token](https://docs.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-a-pat) is required to modify variable groups and secure files.

## `Create-Users-Bulk.ps1`

**What it does?**

Generates a specified number of users, creates their B2C accounts and stores their usernames in a CSV file.

**How to use?**

Use through PowerShell dot-sourcing and then invoke individual functions.

The main function is `Initialize-NewUsersBulk`:

```powershell
. /Create-Users-Bulk.ps1
Initialize-NewUsersBulk -password AllHaveTheSame -B2CTenantName "mytenant"
```

**Requirements**

* PowerShell Core is supported; Windows, Linux, Mac OS are supported.
* `Microsoft.Graph` PowerShell module has to be installed.

## `Create-Users.ps1`

**What it does?**

Creates users in the B2C tenant, which are defined in a JSON file (`users.json`).

```json
{
   "users": [
    {
      "displayName": "Display Name",
      "email": "email@alwayson.demo",
      "gameMaster": true
    },
    {
      "displayName": "Display Name 2",
      "email": "email2@alwayson.demo",
      "gameMaster": false
    }
  ]
}
```

**How to use?**

Use through PowerShell dot-sourcing and then invoke individual functions.

The main function is `Create-Users` (handles Graph authentication):

```powershell
. /Create-Users.ps1
Create-Users -B2CTenantName "mytenant"
```

If a user already exists, an error will be thrown and the script will continue with next user.

**Requirements**

* PowerShell Core is supported; Windows, Linux, Mac OS are supported.
* `Microsoft.Graph` PowerShell module has to be installed.