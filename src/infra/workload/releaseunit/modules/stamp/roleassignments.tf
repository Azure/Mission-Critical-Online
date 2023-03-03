# Permission for AKS to assign the pre-created PIP to its load balancer
# https://learn.microsoft.com/azure/aks/static-ip#create-a-service-using-the-static-ip-address
resource "azurerm_role_assignment" "aks_vnet_contributor" {
  scope                = azurerm_resource_group.stamp.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.stamp.identity.0.principal_id
}

# Permission for AKS to pull images from the globally shared ACR
resource "azurerm_role_assignment" "acrpull_role" {
  scope                = data.azurerm_container_registry.global.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.object_id
}

# Permission for the kubelet as used by the Health Service to query the regional LA workspace
resource "azurerm_role_assignment" "loganalyticsreader_role" {
  scope                = data.azurerm_log_analytics_workspace.stamp.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.healthservice.principal_id
}

# cosmosdb role assignment for catalogservice identity
resource "azurerm_cosmosdb_sql_role_assignment" "catalogservice_contributor" {
  resource_group_name = var.global_resource_group_name
  account_name        = data.azurerm_cosmosdb_account.global.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.builtin_data_contributor.id
  principal_id        = azurerm_user_assigned_identity.catalogservice.principal_id
  scope               = data.azurerm_cosmosdb_account.global.id
}

# cosmosdb role assignment for healthservice identity
resource "azurerm_cosmosdb_sql_role_assignment" "healthservice_contributor" {
  resource_group_name = var.global_resource_group_name
  account_name        = data.azurerm_cosmosdb_account.global.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.builtin_data_contributor.id
  principal_id        = azurerm_user_assigned_identity.healthservice.principal_id
  scope               = data.azurerm_cosmosdb_account.global.id
}

# cosmosdb role assignment for backgroundprocessor identity
resource "azurerm_cosmosdb_sql_role_assignment" "backgroundprocessor_contributor" {
  resource_group_name = var.global_resource_group_name
  account_name        = data.azurerm_cosmosdb_account.global.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.builtin_data_contributor.id
  principal_id        = azurerm_user_assigned_identity.backgroundprocessor.principal_id
  scope               = data.azurerm_cosmosdb_account.global.id
}

resource "azurerm_role_assignment" "backgroundprocessor_blob_contributor" {
  scope                = azurerm_storage_account.private.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.backgroundprocessor.principal_id
}

resource "azurerm_role_assignment" "healthservice_blob_contributor" {
  scope                = azurerm_storage_account.private.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.healthservice.principal_id
}

resource "azurerm_role_assignment" "catalogservice_global_blob_contributor" {
  scope                = data.azurerm_storage_account.global.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.catalogservice.principal_id
}

resource "azurerm_role_assignment" "backgroundprocessor_eh_receiver" {
  scope                = azurerm_eventhub.backendqueue.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_user_assigned_identity.backgroundprocessor.principal_id
}

resource "azurerm_role_assignment" "catalogservice_eh_sender" {
  scope                = azurerm_eventhub.backendqueue.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_user_assigned_identity.catalogservice.principal_id
}

resource "azurerm_role_assignment" "healthservice_eh_sender" {
  scope                = azurerm_eventhub.backendqueue.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_user_assigned_identity.healthservice.principal_id
}