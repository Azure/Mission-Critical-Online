# Deploy an Azure Health Model with a System-assigned Identity
resource "azapi_resource" "azure_health_model" {
  type      = "Microsoft.HealthModel/healthmodels@2022-11-01-preview"
  name      = "${var.prefix}-stamp-${var.location}-hm"

  schema_validation_enabled = false # embedded schema validation is not yet available

  parent_id = azurerm_resource_group.stamp.id # use the resource group as the parent
  location  = azurerm_resource_group.stamp.location # same location as the resource group

  identity {
    type = "SystemAssigned" # use a system-assigned identity (default)
  }
  body = <<-JSON
  {
    "properties": {
      "activeState": "Inactive", 
      "refreshInterval": "PT1M",
      "nodes": [
        {
          "nodeType": "AggregationNode",
          "nodeId": "0",
          "name": "${var.location} stamp",
          "impact": "Standard",
          "childNodeIds": [
            "1",
            "2"
          ],
          "visual": {
            "x": 345,
            "y": 45
          }
        },
        {
            "nodeType": "AzureResourceNode",
            "azureResourceId": "${azurerm_kubernetes_cluster.stamp.id}",
            "nodeId": "1",
            "name": "${azurerm_kubernetes_cluster.stamp.name}",
            "credentialId": "SystemAssigned",
            "childNodeIds": [],
            "queries": [
            {
                "queryType": "ResourceMetricsQuery",
                "metricName": "node_cpu_usage_percentage",
                "metricNamespace": "Microsoft.ContainerService/managedClusters",
                "aggregationType": "Average",
                "queryId": "42b90d7a-ee40-4532-908b-e3c340268169",
                "degradedThreshold": "1",
                "degradedOperator": "GreaterThan",
                "unhealthyThreshold": "85",
                "unhealthyOperator": "GreaterThan",
                "timeGrain": "PT30M",
                "dataUnit": "Percent",
                "enabledState": "Enabled"
            },
            {
                "queryType": "ResourceMetricsQuery",
                "metricName": "node_disk_usage_percentage",
                "metricNamespace": "Microsoft.ContainerService/managedClusters",
                "aggregationType": "Average",
                "queryId": "81cac18b-ed56-450b-857a-d78c6a62b9c8",
                "degradedThreshold": "75",
                "degradedOperator": "GreaterThan",
                "unhealthyThreshold": "90",
                "unhealthyOperator": "GreaterThan",
                "timeGrain": "PT30M",
                "dataUnit": "Percent",
                "enabledState": "Enabled"
            },
            "impact": "Standard"
        },
        {
            "nodeType": "AzureResourceNode",
            "azureResourceId": "${azurerm_eventhub_namespace.stamp.id}",
            "nodeId": "565e7539-6457-48bb-accc-b6d6b5ca1b72",
            "name": "${azurerm_eventhub_namespace.stamp.name}",
            "credentialId": "SystemAssigned",
            "childNodeIds": [],
            "queries": [
                {
                    "queryType": "ResourceMetricsQuery",
                    "metricName": "ServiceAvailability",
                    "metricNamespace": "Microsoft.DocumentDB/databaseAccounts",
                    "aggregationType": "Average",
                    "queryId": "bdce05f3-40c7-4dd1-8381-934940cb9e76",
                    "degradedThreshold": "100",
                    "degradedOperator": "LowerThan",
                    "unhealthyThreshold": "95",
                    "unhealthyOperator": "LowerThan",
                    "timeGrain": "PT1H",
                    "dataUnit": "Percent",
                    "enabledState": "Enabled"
                }
            ],
            "impact": "Standard"
        }
      ]
    }
  }
  JSON

  response_export_values = [ "*" ] # export all response values
}

# Granting the Health Model resource "Monitoring Reader" access on subscription-level.
resource "azurerm_role_assignment" "healthmodel_data_access" {
  scope                = azurerm_resource_group.stamp.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azapi_resource.azure_health_model.identity[0].principal_id
}