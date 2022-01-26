# Policy assignments

# Kubernetes cluster pod security baseline standards for Linux-based workloads (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/Kubernetes_PSPBaselineStandard.json
resource "azurerm_resource_group_policy_assignment" "pod_security_baseline" {
  name                 = "pod-security-baseline"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  display_name         = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

# Kubernetes cluster containers should run with a read only root file system (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Kubernetes/ReadOnlyRootFileSystem.json
resource "azurerm_resource_group_policy_assignment" "readonly_filesystem" {
  name                 = "readonly-filesystem"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/df49d893-a74c-421d-bc95-c663042e5b80"
  display_name         = "Kubernetes cluster containers should run with a read only root file system"
}

# Kubernetes clusters should not allow container privilege escalation (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Kubernetes/ContainerNoPrivilegeEscalation.json
resource "azurerm_resource_group_policy_assignment" "no_privilege_escalation" {
  name                 = "no-privilege-escalation"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1c6e92c9-99f0-4e55-9cf2-0c234dc48f99"
  display_name         = "Kubernetes clusters should not allow container privilege escalation"
}