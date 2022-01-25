# Policy assignments

# Kubernetes cluster pod security baseline standards for Linux-based workloads (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/Kubernetes_PSPBaselineStandard.json
resource "azurerm_resource_group_policy_assignment" "pod_security_baseline" {
  name                 = "pod-security-baseline"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  #description          = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
  display_name         = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

# Kubernetes cluster pods should only use allowed volume types (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Kubernetes/AllowedVolumeTypes.json
resource "azurerm_resource_group_policy_assignment" "readonly_filesystem" {
  name                 = "readonly-filesystem"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/df49d893-a74c-421d-bc95-c663042e5b80"
  #description          = "Kubernetes cluster pods should only use allowed volume types"
  display_name         = "Kubernetes cluster pods should only use allowed volume types"
}