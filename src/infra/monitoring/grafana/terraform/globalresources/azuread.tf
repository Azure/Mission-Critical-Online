data "azuread_client_config" "current" {}

# App registration for the auth manager to be able to validate requests against Azure AD
resource "azuread_application" "auth" {
  display_name     = "${lower(var.prefix)}-auth"
  identifier_uris  = ["api://example-app"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  group_membership_claims = [ "SecurityGroup", "ApplicationGroup" ]

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # ID of Microsoft Graph

    # add group.readwrite.all permissions
    resource_access {
        id   = "5b567255-7703-4780-807c-7be8301ae99b"
        type = "Role"
    }
  }

  # Define a role for grafana read-only users
  app_role {
    allowed_member_types = ["User"]
    description = "Grafana read only users"
    display_name = "Grafana viewer"
    enabled = "true"
    value = "Viewer"
    id = random_uuid.app_role_viewer.result
  }

  # Define a role for grafana administrators
  app_role {
    allowed_member_types = ["User"]
    description = "Grafana org admin users"
    display_name = "Grafana admin"
    enabled = "true"
    value = "Admin"
    id = random_uuid.app_role_admin.result
  }

  web {
    redirect_uris = ["https://${var.custom_fqdn != "" ? var.custom_fqdn : azurerm_frontdoor.afdgrafana.cname}/login/azuread"]

  }
}

resource "random_uuid" "app_role_viewer" {
}

resource "random_uuid" "app_role_admin" {
}

resource "random_uuid" "test" {
}

resource "azuread_application_password" "auth" {
  application_object_id = azuread_application.auth.object_id
}
