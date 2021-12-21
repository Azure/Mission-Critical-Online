# Azure AD B2C Provisioning

The AlwaysOn reference implementation uses Azure AD B2C as its identity provider. To learn more about the design see [Application Design](./AppDesign-Application-Design.md#Authentication).

This document describes the steps needed to recreate the setup.

## Design Decision - Manual Provisioning?

AlwaysOn has not automated the provisioning of Azure AD B2C because:

- It is typically a one-time setup.
- The Azure AD tenant lives outside of the infrastructure lifecycle and is not regularly recreated.
- The tenant usually already exists within an organization and is provided as-is.

Terraform `azuread` provider supports the creation and management of application registrations, but currently (September 2021) [it is not able](https://github.com/hashicorp/terraform-provider-azuread/issues/175) to manage all of the required settings (such as user flows and B2C user access). PowerShell and Microsoft Graph could be used to automate these steps, but that would bring additional overhead.

It was decided that to have users follow a series of steps in the Azure Portal is easier and efficient enough for this particular one-time task.

## Overview

In high level, the B2C deployment process includes these steps:

1. Create the Azure AD B2C tenant.
1. Create application registration for the UI and configure correct access scopes.
1. Create the Game Master custom attribute.
1. Create two user flows - for regular sign-in and ROPC headless sign-in.
1. Create sample users.
1. Set up Microsoft Graph access.
1. (Optional) Configure local development.
1. After the application infrastructure gets deployed, update redirect URLs.

## PowerShell script

For convenience, there's a PowerShell script: `/src/config/identity/Create-AzureB2C.ps1`, which automates most of the steps outlined in the *Overview* above. It's still considered manual provisioning, designed to be executed from an administrator's machine instead of automation pipeline.

Usage:

```powershell
. ./Create-AzureB2C.ps1 # dot-source the main script file
Initialize-B2CTenant -B2CTenantName mynewtenant -ResourceGroupName myrg -Location "Europe" -CountryCode "GB"
```

Parameters:

- `B2CTenantName` is the name of a tenant to be created. It shouldn't contain the `.onmicrosoft.com` part and should be unique.
- `ResourceGroupName` is the Azure resource group where the tenant resource will be placed. It will be created in `northeurope` if non-existent.
- `Location` can be one of 'United States', 'Europe', 'Asia Pacific', or 'Australia' (preview). This value is independent on the Azure region where the tenant resource is deployed.
- `CountryCode` is a two-letter country code (e.g. 'US', 'CZ', 'DE'). Valid country codes are listed [in the Docs](https://docs.microsoft.com/azure/active-directory-b2c/data-residency).

Requirements:

- `Microsoft.Graph` PowerShell module must be installed and imported.
- Azure CLI must be installed, available in PATH and authenticated with Azure account t hat can manage the resource group.
- Resource provider `Microsoft.AzureActiveDirectory` must be registered (the script does it automatically).

The script will pop-up a sign in page for interactive login to Microsoft Graph, once the tenant is created. The required scopes are: "User.ReadWrite.All", "Application.ReadWrite.All", "Directory.AccessAsUser.All" and "Directory.ReadWrite.All". After that it will run without any additional input.

Besides the overarching function `Initialize-B2CTenant`, the script file contains functions for each of the steps in the process, which can be called individually as well.

### Microsoft Graph service principal

To allow Azure DevOps pipelines access to Microsoft Graph for Redirect URI updates after deployments, an additional service principal needs to be created once the B2C tenant is provisioned. This service principal will use the [app-only authentication](https://docs.microsoft.com/graph/powershell/app-only?tabs=azure-portal) with self-signed certificates.

To make the setup process easier, there's a PowerShell script which automates large part of it: [`Create-ServicePrincipal.ps1`](/src/config/identity/Create-ServicePrincipal.ps1). Use it with dot-sourcing:

```powershell
. ./Create-ServicePrincipal.ps1
Create-ServicePrincipal -AppName "ADO Graph Client" -TenantId "myb2c.onmicrosoft.com" -AdoOrganization "https://dev.azure.com/myorg" -AdoProjectName "alwaysonapplication" -AdoPAT "mypatvalue" -AdoVariableGroupName "e2e-env-vg"
```

> Note: Executing this script on macOS or a Unix-based system (incl WSL) requires that [openssl](https://www.openssl.org/) is installed and available in the PATH.

Where:

- `AppName` will be the display name in B2C application registrations.
- `TenantId` is the target B2C tenant where the service principal will be created.
- `AdoOrganization` is the full ADO organization name, including https://. Example: https://dev.azure.com/myorg
- `AdoProjectName` is the name of project in Azure DevOps (what follows the organization name).
- `AdoPAT` is the Personal Access Token which has read/write access to variable groups and secure files. ([How to: Create a PAT](https://docs.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-a-pat))
- `AdoVariableGroupName` is the variable group to be updated.

The script first interactively authenticates with the B2C tenant - an admin account should be used.

Then a self-signed certificate is created. **Make note of the password, in case it's needed in the future.**

![](/docs/media/b2c-create-sp-certificate.png)

Then the script creates an application registration, a service principal and automatically grants admin consent.

![](/docs/media/b2c-create-sp.png)

The script then updates Azure DevOps with values generated earlier: certificate name and password, and uploads the PFX file to ADO Secure files.

## Azure Portal

### Create Azure resources

The Azure AD B2C tenant is a regular Azure resource and can not currently be created via Terraform. It should be created in a separate Resource group as it does not share the same lifecycle as the regional deployments and will likely be used for applications other than AlwaysOn.

1. Create the Resource group.
1. Click **Create**, search for **Azure Active Directory B2C** and click **Create** again.
1. Select **Create a new Azure AD B2C Tenant**.
    - ![Create new B2C tenant](/docs/media/b2c-create-new-tenant.png)
1. Pick organization name and initial domain name (needs to be globally unique).
    - ![Enter organization name and domain name](/docs/media/b2c-pick-name.png)
1. Select country (which will determine the datacenter location) (we usually use **United Kingdom**).
1. Click **Create**.

Tenant creation will take a few seconds and a notification will be shown in the Azure portal when finished:

![B2C tenant was successfully created](/docs/media/b2c-tenant-creation-successful.png)

As a new tenant was created, Azure portal needs to switch to it in order to manage users, applications etc. This transition might be a bit confusing, but keep in mind that it is a new ".onmicrosoft.com" domain and different from the tenant where the B2C resource was created.

To quickly switch to this tenant later, go to the Resource group in Azure, select the B2C resource and click the **Azure AD B2C Settings** button.

![Switch B2C tenant from Azure](/docs/media/b2c-tenant-switch.png)

### Register Application in Azure AD B2C

Next, we'll have to create an application registration for the UI application. The API doesn't necessarily need one because we will use the user flow and custom attributes defined below to manage sign-in.

1. Go to **App registrations** and then click **New registration**.
1. Enter a descriptive name (`AlwaysOn UI` in our case).
1. **Supported account types** value must be: `Accounts in any identity provider or organizational directory (for authenticating users with user flows)`
  
    ![Create UI app registration](/docs/media/b2c-create-alwayson-ui-app-registration.png)
1. For development enter redirect URI as "Single-page application (SPA) - `http://localhost:8080`".
    ![Redirect URI for SPA](/docs/media/b2c-redirect-uri-spa.png)

    - For existing cloud environments (int, prod, e2e), enter the URL of the public endpoint (e.g. `https://ao1234.azurefd.net`).
    - In order for the authentication to work across environments, this list needs to be kept up-to-date and contain all actively used URLs (and not more).
1. Click **Register**.

When the app is created, make a note of the **Application (client) ID**. We will refer to it further as the "UI Client ID".

![UI application Client ID](/docs/media/b2c-ui-application-id.png)

1. Go to the **Authentication** blade.
1. Make sure that the **Access tokens** and **ID tokens** checkboxes are selected.
1. Set **Allow public client flows** to **Yes**.

![Set tokens and public client flow](/docs/media/b2c-tokens-public-flow.png)

1. Go to the **Expose an API** blade.
1. Click the **Set** link next to **Application ID URI**.
  
    ![Set application URI](/docs/media/b2c-set-application-id-uri.png)
1. Accept the default.
1. Click **Add scope**.
1. Enter scope name: `Games.Access` and admin consent display name and description.
  
    ![Add scope](/docs/media/b2c-add-scope.png)
1. Click **Add scope**.
1. Switch to the **API permissions** blade.
1. Click **Add a permission**.
1. Switch to **APIs my organization uses**.
1. Select **AlwaysOn UI**.

    ![Request API permissions](/docs/media/b2c-request-api-permissions.png)
1. Select **Games.Access** scope, then select **Add permissions**.

    ![Games.Access scope](/docs/media/b2c-select-claims.png)

1. Click **Grant admin consent for [tenant]**.
  
    ![Grant admin consent](/docs/media/b2c-grant-admin-consent.png)

> This setup is a simplification of proper API protection. More traditional approach would be to set up UI and API as two separate apps and link them through permissions. This is not in scope for AlwaysOn, so for simplicity the UI app registration serves also the API app's role.

### Add Custom Attribute

To demonstrate the use of custom user attributes, AlwaysOn defines a custom boolean attribute called `GameMaster`, which indicates if a particular user has permissions to manage games, players and leaderboards (`true`) or not (`false`).

> This decision is a result of Azure AD B2C [not supporting group membership in claims](https://feedback.azure.com/forums/169401-azure-active-directory/suggestions/10123836-get-user-membership-groups-in-the-claims-with-ad-b) without creating a Custom Policy.

1. Navigate back to the B2C tenant configuration and select **User attributes**.
1. Click **Add**.
1. Put `GameMaster` as the **Name**.
1. Change **Data Type** to `Boolean`.
1. Click **Create**.

![Add GameMaster attribute](/docs/media/b2c-gamemaster-attribute.png)

### Create Sign-In User Flow

We decided to not allow users register themselves, so the [user flow](https://docs.microsoft.com/azure/active-directory-b2c/user-flow-overview) needed for login would be sign-in, using one of the pre-provisioned accounts.

1. Navigate back to your B2C tenant configuration and select **User flows**.
1. Click **New user flow**.
1. Select **Sign in**.
    
     ![Sign in flow type](/docs/media/b2c-sign-in-flow-type.png)
1. Leave the **Recommended** version selected.
1. Click **Create**.
1. Enter `signin` in the **Name** field in section 1.
    - Full policy name will be `B2C_1_signin`.
1. Select **Email signin** as the identity provider in section 2.
1. In section 5 click **Show more...** and select:
    - `Display Name`
    - `Email Addresses`
    - `GameMaster`
    - `User's Object ID`
    
    ![Selected claims to return](/docs/media/b2c-return-claims.png)
1. Click **Ok**.
1. Finally, click **Create**.

### Create ROPC user flow

In order to enable automated testing and direct API access, the second login flow that AlwaysOn uses is the [ROPC (Resource owner password credentials) flow](https://docs.microsoft.com/azure/active-directory-b2c/add-ropc-policy?tabs=app-reg-ga&pivots=b2c-user-flow). This allows the exchange of username and password for an access token in order to call the APIs.

1. Navigate back to your B2C tenant configuration and select **User flows**.
1. Click **New user flow**.
1. Select **Sign in using resource owner password credentials (ROPC)**.
1. Click **Create**.
1. Enter `ropc_signin` in the **Name** field in section 1.
    - Full policy name will be `B2C_1_ropc_signin`.
1. In section 2 click **Show more...** and select:
    - `Display Name`
    - `Email Addresses`
    - `GameMaster`
    - `User's Object ID`
1. Click **Ok**.
1. Click **Create**.

### Create users

To create users with custom attributes, you can use Microsoft Graph REST APIs, [.NET sample application](https://github.com/Azure-Samples/ms-identity-dotnetcore-b2c-account-management) or PowerShell scripts provided in this repo.

#### PowerShell

We prepared a handful of users and stored them in [`/src/config/identity/users.json`](/src/config/identity/users.json). Please make sure to change the sample passwords before importing! You can change the user names (email addresses) to reflect real values, but since no emails will be sent to those, they don't have to be real accounts.

 There is also a [`Create-Users.ps1`](/src/config/identity/Create-Users.ps1) script in the same directory which creates those users in Azure AD B2C. This script creates a function `Import-Users` which then creates the users.

To use this script, make sure you have the **Microsoft.Graph** PowerShell module [installed](https://docs.microsoft.com/powershell/microsoftgraph/installation?view=graph-powershell-1.0). This module works on PowerShell Core and supports all operations that are needed to create B2C users with custom attributes.

```powershell
Install-Module Microsoft.Graph

# (optional) Check if module was installed
Get-InstalledModule Microsoft.Graph
```

Once the module has been installed, run `Import-Users` function from the command-line with the `-tenantId` parameter to reflect your newly created tenant.

```powershell
Import-Users -tenantId "<tenant>.onmicrosoft.com"
```
When run, the script asks for login in AAD pop-up. Use an account which has administrative privileges Minimum scopes that the user needs to have access to are: `User.ReadWrite.All` and `Application.Read.All`.

> This simple method for interactive login was chosen instead of using service principals because this script is not supposed to be used as part of any automation pipeline and will be run only once to provision default users. This method eliminates the need to create the service principal application, store/rotate secrets etc.

#### AAD portal

It's also possible to create test users via the AAD portal, but consider following:

- The portal UI does not support custom attributes and so you **can't create Game Masters**.
- When asked for user type you **must** select **Create Azure AD B2C user**.
  - ![Select Create Azure AD B2C User](/docs/media/b2c-create-user-b2cuser.png)

- Select **Email** as the **Sign in method** and fill any e-mail address you want the user to use for login.

### Microsoft Graph Access

As both the client application and GameService API only have access to the Azure AD claim data of the currently signed in user, it was necessary to implement a player name resolution mechanism for the ResultWorker in order to enhance game results, leaderboards and player data with actual names of players (besides their IDs and e-mail addresses). Azure AD B2C supports Microsoft Graph APIs and the following steps are required to enable access to user information:

1. Create new **App registration** in the Azure AD B2C tenant.
    1. Choose an appropriate name such as `AlwaysOn Graph Client`.
    1. Make sure that **Supported account types** is set to **Accounts in any identity provider or organizational directory (for authenticating users with user flows)**.
    1. Leave **Redirect URI** empty.
    1. Unselect the **Grant admin consent to openid and offline_access permissions** checkbox.
1. Open the newly registered application and make a note of the **Application (client) ID**.
1. Go to **Certificates and secrets**.
1. In the **Client secrets** section, click **New client secret**.
  ![Create new secret for the Graph Client](/docs/media/b2c-create-graph-secret.png)
1. Enter description, expiration period and click **Add**.
1. **Make note of `value`** - once you leave this page, it cannot be shown again.
  ![Copy secret value](/docs/media/b2c-copy-secret.png)
1. Go to **API permissions**.
1. Click **Add a permission**.
1. Select **Microsoft Graph**, then **Application permissions** and search for **`User.Read.All`**.
  ![Select User.Read.All permissions](/docs/media/b2c-user-read-all.png)
1. Click **Add permissions**.
1. Back in the list of permissions, click **Grant admin consent for "tenant name"** and confirm.

Finally, update your deployment pipeline's configuration to include `b2cResultWorkerClientID` and `b2cResultWorkerClientSecret`:

1. Depending on the environment, find the `variables-values-<env>.yaml` file ([E2E config file as an example](/.ado/pipelines/config/variables-values-e2e.yaml)).
1. Set `b2cResultWorkerClientID` value to your ResultWorker application's clientID.
1. Go to Azure DevOps -> Library -> **Variable Groups**.
1. Depending on the environment, open the right variable group.
1. Set the `b2cResultWorkerClientSecret` value to your ResultWorker application's client secret and change the variable type to secret.
1. **Save** the variable group.

### Local development setup

In order to work with the application locally and have authentication in place, you must setup the tenant information and client ID in both the UI app and GameService API.

*/src/app/AlwaysOn.UI/public/config.js*

```javascript
// Use these values for local development.
// This whole file will be replaced during deployment, with environment appropriate values.
window.API_URL = "http://localhost:5000"; // without the trailing "/"
window.APPINSIGHTS_INSTRUMENTATIONKEY = "";

window.CLIENT_ID = "";
window.TENANT_NAME = "";
window.POLICY_NAME = "b2c_1_signin";
```

Replace `CLIENT_ID`, `TENANT_NAME`, `SIGNIN_POLICY_NAME` and `ROPC_SIGNIN_POLICY_NAME` values with the information from your tenant.

*/src/app/AlwaysOn.GameService/appsettings.development.json*

```json
{
  "...": "...",
  "B2C_TENANT_NAME": "",
  "B2C_UI_CLIENTID": "",
  "B2C_SIGNIN_POLICY_NAME": "b2c_1_signin",
  "B2C_ROPC_POLICY_NAME": "b2c_1_ropc_signin"
}
```

Make sure that one of the Redirect URIs in the AlwaysOn UI application registration is `http://localhost:8080` (URL of the locally running UI app).

### Update Redirect URIs

> Note: This step can only be completed once the an environment is successfully deployed.

To make authentication work in the UI application, the list of redirect URIs needs to be regularly updated. Typically you would do it once for production/int environment and every time after a new E2E environment is created or removed.

Deployment pipeline handles the update automatically during the *Deploy Workload* step. Following manual steps are for reference only:

1. Navigate to your B2C tenant configuration and select **App registrations**.
1. Select the `AlwaysOn UI` application.
1. Go to **Authentication**.
1. In the **Single-page application** section, add the URL of your newly created environment, or remove the URL of a deleted environment. Use the publicly accessed endpoint, where the UI application is available (either custom domain, or Front Door endpoint).
   
   ![Redirect URIs list](/docs/media/b2c-update-redirect-uris.png)
1. Click **Save**.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
