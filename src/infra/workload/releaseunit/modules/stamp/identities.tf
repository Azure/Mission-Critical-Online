# managed identity used for catalogservice
resource "azurerm_user_assigned_identity" "catalogservice" {
  # temporary workaround while the creation of federated identity credentials is not supported on user-assigned managed identities in some regions
  # https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-considerations#unsupported-regions-user-assigned-managed-identities
  location            = azurerm_resource_group.stamp.location
  name                = "catalogservice"
  resource_group_name = azurerm_resource_group.stamp.name
}

resource "azurerm_federated_identity_credential" "catalogservice" {
  name                = azurerm_user_assigned_identity.catalogservice.name
  resource_group_name = azurerm_resource_group.stamp.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.stamp.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.catalogservice.id
  subject             = "system:serviceaccount:workload:catalogservice-identity"
}

# managed identity used for healthservice
resource "azurerm_user_assigned_identity" "healthservice" {
  # temporary workaround while the creation of federated identity credentials is not supported on user-assigned managed identities in some regions
  # https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-considerations#unsupported-regions-user-assigned-managed-identities
  location            = azurerm_resource_group.stamp.location
  name                = "healthservice"
  resource_group_name = azurerm_resource_group.stamp.name
}

resource "azurerm_federated_identity_credential" "healthservice" {
  name                = azurerm_user_assigned_identity.healthservice.name
  resource_group_name = azurerm_resource_group.stamp.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.stamp.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.healthservice.id
  subject             = "system:serviceaccount:workload:healthservice-identity"
}

# managed identity used for backgroundprocessor
resource "azurerm_user_assigned_identity" "backgroundprocessor" {
  # temporary workaround while the creation of federated identity credentials is not supported on user-assigned managed identities in some regions
  # https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-considerations#unsupported-regions-user-assigned-managed-identities
  location            = azurerm_resource_group.stamp.location
  name                = "backgroundprocessor"
  resource_group_name = azurerm_resource_group.stamp.name
}

resource "azurerm_federated_identity_credential" "backgroundprocessor" {
  name                = azurerm_user_assigned_identity.backgroundprocessor.name
  resource_group_name = azurerm_resource_group.stamp.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.stamp.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.backgroundprocessor.id
  subject             = "system:serviceaccount:workload:backgroundprocessor-identity"
}
