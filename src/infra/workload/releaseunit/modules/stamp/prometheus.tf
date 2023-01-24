resource "azapi_resource" "dataCollectionRule" {
  schema_validation_enabled = false

  type      = "Microsoft.Insights/dataCollectionRules@2021-09-01-preview"
  name      = "${local.prefix}-${local.location_short}-dcr"
  parent_id = azurerm_resource_group.stamp.id
  location  = azurerm_resource_group.stamp.location

  body = jsonencode({
    kind = "Linux"
    properties = {
      dataCollectionEndpointId = azapi_resource.dataCollectionEndpoint.id
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
  name      = "${local.prefix}-${local.location_short}-dce"
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
  name                      = "${local.prefix}-${local.location_short}-dcra"
  parent_id                 = azurerm_kubernetes_cluster.stamp.id
  #location                  = azurerm_resource_group.stamp.location

  body = jsonencode({
    scope = azurerm_kubernetes_cluster.stamp.id
    properties = {
      dataCollectionRuleId = azapi_resource.dataCollectionRule.id
    }
  })
}

resource "azapi_resource" "prometheusRuleGroup" {
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2021-07-22-preview"
  name      = "${local.prefix}-${local.location_short}-ruleGroup"
  parent_id = azurerm_resource_group.stamp.id
  location  = azurerm_resource_group.stamp.location

  body = jsonencode({
    properties = {
      description = "Prometheus Rule Group"
      scopes      = [data.azapi_resource.prometheus.id]
      enabled     = true
      clusterName = azurerm_kubernetes_cluster.stamp.name
      interval    = "PT1M"

      rules = [
        {
          record = "instance:node_cpu_utilisation:rate5m"
          expression = "1 - avg without (cpu) (sum without (mode)(rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
          labels = {
              workload_type = "job"
          }
          enabled = true
        },
        {
          record = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
          expression = "sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
          labels = {
            workload_type = "job"
          }
          enabled = true
        }
      ]
    }
  })
}