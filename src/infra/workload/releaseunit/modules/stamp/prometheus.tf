resource "azapi_resource" "dataCollectionRule" {
  schema_validation_enabled = false

  type      = "Microsoft.Insights/dataCollectionRules@2021-09-01-preview"
  name      = "MSPROM-SUK-${azurerm_kubernetes_cluster.stamp.name}"
  parent_id = azurerm_resource_group.stamp.id
  location  = azurerm_resource_group.stamp.location

  body = jsonencode({
    kind = "Linux"
    properties = {
      dataCollectionEndpointId = jsondecode(data.azapi_resource.prometheus.output).properties.defaultIngestionSettings.dataCollectionEndpointResourceId
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
            accountResourceId = data.azapi_resource.prometheus.id
            name              = "MonitoringAccount1"
          }
        ]
      }
    }
  })
}

resource "azapi_resource" "dataCollectionEndpoint" {
  type      = "Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview"
  name      = "MSPROM-SUK-${azurerm_kubernetes_cluster.stamp.name}"
  parent_id = azurerm_resource_group.stamp.id
  location  = azurerm_resource_group.stamp.location

  body = jsonencode({
    kind       = "Linux"
    properties = {}
  })
}

resource "azapi_resource" "dataCollectionRuleAssociation" {
  schema_validation_enabled = false
  type                      = "Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview"
  name                      = "${local.prefix}-prom-dcra"
  parent_id                 = azurerm_kubernetes_cluster.stamp.id
  location                  = azurerm_resource_group.stamp.location

  body = jsonencode({
    properties = {
      dataCollectionRuleId = jsondecode(data.azapi_resource.prometheus.output).properties.defaultIngestionSettings.dataCollectionRuleResourceId
    }
  })
}