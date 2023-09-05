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
            "2",
            "3"
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
                }
            ],
            "impact": "Standard"
        },
        {
            "nodeType": "AzureResourceNode",
            "azureResourceId": "${azurerm_eventhub_namespace.stamp.id}",
            "nodeId": "2",
            "name": "${azurerm_eventhub_namespace.stamp.name}",
            "credentialId": "SystemAssigned",
            "childNodeIds": [],
            "queries": [
                {
                    "queryType": "ResourceMetricsQuery",
                    "metricName": "ServerErrors",
                    "metricNamespace": "Microsoft.EventHub/namespaces",
                    "aggregationType": "Average",
                    "queryId": "95936847-5b8e-4543-8ddd-fd08cc406615",
                    "degradedThreshold": "1",
                    "degradedOperator": "GreaterThan",
                    "unhealthyThreshold": "10",
                    "unhealthyOperator": "GreaterThan",
                    "timeGrain": "PT1H",
                    "dataUnit": "Count",
                    "enabledState": "Enabled"
                }
            ],
            "impact": "Standard"
        },
        {
            "nodeType": "AzureResourceNode",
            "azureResourceId": "${azurerm_key_vault.stamp.id}",
            "nodeId": "3",
            "name": "KeyVault",
            "credentialId": "SystemAssigned",
            "childNodeIds": [],
            "queries": [
                {
                    "queryType": "ResourceMetricsQuery",
                    "metricName": "Availability",
                    "metricNamespace": "Microsoft.KeyVault/vaults",
                    "aggregationType": "Average",
                    "queryId": "d6f7519f-f73c-4690-80a6-6ae6fcbece8d",
                    "degradedThreshold": "99",
                    "degradedOperator": "LowerThan",
                    "unhealthyThreshold": "95",
                    "unhealthyOperator": "LowerThan",
                    "timeGrain": "PT30M",
                    "dataUnit": "Percent",
                    "enabledState": "Enabled"
                },
                {
                    "queryType": "ResourceMetricsQuery",
                    "metricName": "SaturationShoebox",
                    "metricNamespace": "Microsoft.KeyVault/vaults",
                    "aggregationType": "Average",
                    "queryId": "511677bf-2c92-4da7-93c6-ad6ede24e500",
                    "degradedThreshold": "25",
                    "degradedOperator": "GreaterThan",
                    "unhealthyThreshold": "50",
                    "unhealthyOperator": "GreaterThan",
                    "timeGrain": "PT30M",
                    "dataUnit": "Percent",
                    "enabledState": "Enabled"
                },
                {
                    "queryType": "ResourceMetricsQuery",
                    "metricName": "ServiceApiLatency",
                    "metricNamespace": "Microsoft.KeyVault/vaults",
                    "aggregationType": "Average",
                    "queryId": "d66c380b-ac99-4ab6-b3b5-1c62088f6e2c",
                    "degradedThreshold": "30",
                    "degradedOperator": "GreaterThan",
                    "unhealthyThreshold": "60",
                    "unhealthyOperator": "GreaterThan",
                    "timeGrain": "PT15M",
                    "dataUnit": "MilliSeconds",
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