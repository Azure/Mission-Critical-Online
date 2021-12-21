# Policy assignments

# Kubernetes cluster pod security baseline standards for Linux-based workloads (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/Kubernetes_PSPBaselineStandard.json
resource "azurerm_resource_group_policy_assignment" "pod_security_baseline" {
  name                 = "pod-security-baseline"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  description          = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
  display_name         = "Pod Security Baseline"
}