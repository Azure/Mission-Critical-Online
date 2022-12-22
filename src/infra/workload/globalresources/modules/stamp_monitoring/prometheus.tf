resource "azapi_resource" "prometheus" {
  type      = "microsoft.monitor/accounts@2021-06-03-preview"
  name      = "${local.prefix}-prometheus"
  parent_id = var.resource_group_id
  location  = var.location

  response_export_values = ["*"]
}

# resource "azapi_resource" "grafana" {
#   type      = "Microsoft.Dashboard/grafana@2022-08-01"
#   name      = "${local.prefix}-grafana"
#   parent_id = var.resource_group_id
#   location  = var.location

#   identity {
#     type = "SystemAssigned"
#   }

#   body = jsonencode({
#     sku = {
#       name = "Standard"
#     }
#     properties = {
#       zoneRedundancy          = "Enabled"
#       apiKey                  = "Disabled"
#       deterministicOutboundIP = "Disabled"
#       grafanaIntegrations = {
#         azureMonitorWorkspaceIntegrations = [
#           {
#             azureMonitorWorkspaceResourceId = azapi_resource.prometheus.id
#           }
#         ]
#       }
#     }
#   })
# }

# resource "azurerm_role_assignment" "grafana_monitoring_reader" {
#   scope = azapi_resource.prometheus.id
#   # scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
#   role_definition_name = "Monitoring Data Reader"
#   principal_id         = azapi_resource.grafana.identity[0].principal_id
# }

resource "azapi_resource" "dataCollectionEndpoint" {
  type      = "Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview"
  name      = "${local.prefix}-${local.location_short}-prom-dce"
  parent_id = var.resource_group_id
  location  = var.location

  body = jsonencode({
    kind       = "Linux"
    properties = {}
  })
}

resource "azapi_resource" "dataCollectionRule" {
  schema_validation_enabled = false

  type      = "Microsoft.Insights/dataCollectionRules@2021-09-01-preview"
  name      = "${local.prefix}-${local.location_short}-prom-dcr"
  parent_id = var.resource_group_id
  location  = var.location

  body = jsonencode({
    kind = "Linux"
    properties = {
      dataCollectionEndpointId = jsondecode(azapi_resource.prometheus.output).properties.defaultIngestionSettings.dataCollectionEndpointResourceId
      dataFlows = [
        {
          destinations = ["MonitoringAccount1"]
          streams      = ["Microsoft-PrometheusMetrics"]
        }
      ]
      dataSources = {
        prometheusForwarder = [
          {
            name               = "PrometheusDataSource"
            streams            = ["Microsoft-PrometheusMetrics"]
            labelIncludeFilter = {}
          }
        ]
      }
      destinations = {
        monitoringAccounts = [
          {
            accountResourceId = azapi_resource.prometheus.id
            name              = "MonitoringAccount1"
          }
        ]
      }
    }
  })
}

# resource "azapi_resource" "dataCollectionRuleAssociation" {
#   schema_validation_enabled = false
#   type                      = "Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview"
#   name                      = "${local.prefix}-prom-dcra"
#   parent_id                 = azurerm_kubernetes_cluster.stamp.id
#   location                  = azurerm_resource_group.stamp.location

#   body = jsonencode({
#     properties = {
#       dataCollectionRuleId = jsondecode(azapi_resource.prometheus.output).properties.defaultIngestionSettings.dataCollectionRuleResourceId
#     }
#   })
# }