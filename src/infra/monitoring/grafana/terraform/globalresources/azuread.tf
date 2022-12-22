data "azuread_client_config" "current" {}

# App registration for the auth manager to be able to validate requests against Azure AD
resource "azuread_application" "auth" {
  display_name     = "${lower(var.prefix)}-auth"
  identifier_uris  = ["api://example-app"]
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_application_password" "auth" {
  application_object_id = azuread_application.auth.object_id
}
