resource "azurerm_portal_dashboard" "global_board" {
  name                = "${local.prefix}-global-dashboard"
  resource_group_name = var.monitoring_resource_group_name
  location            = var.stamps[0]
  tags                = merge(local.default_tags, { "hidden-title" = "[${var.environment}] Dashboard - ${local.prefix}" }) # the hidden-title tag is used to set the Display Name of the dashboard

  # Using this template we are assuing 2 stamps are being deployed. less will use the fallback values that would lead to the visuals not displaying.
  # TODO look at making this more dynamic with whatever tool so that we can create the dashboard and elements dynamically from code.
  dashboard_properties = templatefile("${path.root}/../../monitoring/dashboards/globaldashboard.tpl",
    {
      stamp_label      = length(var.stamps) == 1 ? "(single stamp deployment)" : "(showing 2 stamps)"
      stamp_location_0 = try(var.stamps[0], "Unavailable")
      stamp_location_1 = try(var.stamps[1], "Unavailable")

      stamp_appi_id_0   = try(module.stamp[var.stamps[0]].app_insights_id, "Unavailable")
      stamp_appi_id_1   = try(module.stamp[var.stamps[1]].app_insights_id, "Unavailable")
      stamp_appi_name_0 = try(module.stamp[var.stamps[0]].app_insights_name, "Unavailable")
      stamp_appi_name_1 = try(module.stamp[var.stamps[1]].app_insights_name, "Unavailable")

      stamp_eventhub_id_0 = try(module.stamp[var.stamps[0]].eventhub_id, "Unavailable")
      stamp_eventhub_id_1 = try(module.stamp[var.stamps[1]].eventhub_id, "Unavailable")

      stamp_aks_id_0   = try(module.stamp[var.stamps[0]].aks_cluster_id, "Unavailable")
      stamp_aks_id_1   = try(module.stamp[var.stamps[1]].aks_cluster_id, "Unavailable")
      stamp_aks_name_0 = try(module.stamp[var.stamps[0]].aks_cluster_name, "Unavailable")
      stamp_aks_name_1 = try(module.stamp[var.stamps[1]].aks_cluster_name, "Unavailable")

      front_door_id   = var.frontdoor_resource_id
      front_door_name = var.frontdoor_name

      cosmosdb_id = data.azurerm_cosmosdb_account.global.id

      tenant_id = data.azurerm_client_config.current.tenant_id
  })
}