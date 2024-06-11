locals {
  # regions where the creation of azure monitor workspaces and related resources is currently not supported - with a fallback region provided
  region_fallbacks = {
    "australiaeast" = "australiasoutheast"
  }
}

resource "azurerm_monitor_data_collection_endpoint" "stamp" {
  name                          = "${local.prefix}-${local.location_short}-dce"
  resource_group_name           = azurerm_resource_group.stamp.name
  location                      = lookup(local.region_fallbacks, var.location, var.location) # If the region is set in the region_fallbacks maps, we use the fallback, otherwise the region as chosen by the user
  kind                          = "Linux"
  public_network_access_enabled = true
  description                   = "monitor_data_collection_endpoint example"
}

resource "azurerm_monitor_data_collection_rule" "stamp" {
  name                        = "${local.prefix}-${local.location_short}-dcr"
  resource_group_name         = azurerm_resource_group.stamp.name
  location                    = lookup(local.region_fallbacks, var.location, var.location)
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.stamp.id
  kind                        = "Linux"

  data_flow {
    destinations = ["MonitoringAccount1"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = data.azapi_resource.azure_monitor_workspace.id
      name               = "MonitoringAccount1"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks" {
  name                    = "${local.prefix}-${local.location_short}-dcra"
  target_resource_id      = azurerm_kubernetes_cluster.stamp.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.stamp.id
}

resource "azurerm_monitor_alert_prometheus_rule_group" "prometheusK8sRuleGroup" {
  name                = "${local.prefix}-${local.location_short}-k8sRuleGroup"
  location            = lookup(local.region_fallbacks, var.location, var.location) # If the region is set in the region_fallbacks maps, we use the fallback, otherwise the region as chosen by the user
  resource_group_name = azurerm_resource_group.stamp.name
  cluster_name        = azurerm_kubernetes_cluster.stamp.name
  description         = "Prometheus Rule Group"
  rule_group_enabled  = false
  interval            = "PT1M"
  scopes              = [data.azapi_resource.azure_monitor_workspace.id]

  rule {
    enabled    = true
    expression = "1 - avg without (cpu) (sum without (mode)(rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
    record     = "instance:node_cpu_utilisation:rate5m"
    labels = {
      workload_type = "job"
    }
  }

  rule {
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
    expression = "sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    labels = {
      workload_type = "job"
    }
    enabled = true
  }

}

resource "azurerm_monitor_alert_prometheus_rule_group" "prometheusNodeRuleGroup" {
  name                = "${local.prefix}-${local.location_short}-nodeRuleGroup"
  location            = lookup(local.region_fallbacks, var.location, var.location) # If the region is set in the region_fallbacks maps, we use the fallback, otherwise the region as chosen by the user
  resource_group_name = azurerm_resource_group.stamp.name
  cluster_name        = azurerm_kubernetes_cluster.stamp.name
  description         = "Prometheus Rule Group"
  rule_group_enabled  = false
  interval            = "PT1M"
  scopes              = [data.azapi_resource.azure_monitor_workspace.id]

  rule {
    record     = "instance:node_load1_per_cpu:ratio"
    expression = "(node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
    labels = {
      workload_type = "job"
    }
    enabled = true
  }
}
