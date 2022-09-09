# Permission for AKS to assign the pre-created PIP to its load balancer
# https://docs.microsoft.com/azure/aks/static-ip#create-a-service-using-the-static-ip-address
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
  principal_id         = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.object_id
}