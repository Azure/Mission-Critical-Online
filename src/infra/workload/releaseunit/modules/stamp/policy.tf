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

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "chaos-testing",
          "ingress-nginx"
        ]
      }
    }
PARAMS
}

# Azure Policy Add-on for Kubernetes service (AKS) should be installed and enabled on your clusters (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Kubernetes/AKS_AzurePolicyAddOn_Audit.json
resource "azurerm_resource_group_policy_assignment" "azure_policy_on_aks" {
  name                 = "azure-policy-enabled-on-aks"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a15ec92-a229-4763-bb14-0ea34a568f8d"
  display_name         = "Azure Policy Add-on for Kubernetes service (AKS) should be installed and enabled on your clusters"
}

# Kubernetes cluster should not allow privileged containers (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Kubernetes/ContainerNoPrivilege.json
resource "azurerm_resource_group_policy_assignment" "no_privileged_containers" {
  name                 = "no-privileged-containers"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/95edb821-ddaf-4404-9732-666045e056b4"
  display_name         = "Kubernetes cluster should not allow privileged containers"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "chaos-testing"
        ]
      }
    }
PARAMS
}

# Role-Based Access Control (RBAC) should be used on Kubernetes Services (BuiltIn)
# https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Security%20Center/ASC_EnableRBAC_KubernetesService_Audit.json
resource "azurerm_resource_group_policy_assignment" "aks_rbac_enabled" {
  name                 = "aks-rbac-enabled"
  resource_group_id    = azurerm_resource_group.stamp.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ac4a19c2-fa67-49b4-8ae5-0b2e78c49457"
  display_name         = "Role-Based Access Control (RBAC) should be used on Kubernetes Services"
}