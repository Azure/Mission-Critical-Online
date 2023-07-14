resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = local.frontdoor_name
  resource_group_name      = azurerm_resource_group.global.name
  response_timeout_seconds = 120

  sku_name = "Premium_AzureFrontDoor"
  tags     = local.default_tags
}

# Default Front Door endpoint
resource "azurerm_cdn_frontdoor_endpoint" "default" {
  name    = "${local.prefix}-primaryendpoint" # needs to be a gloablly unique name
  enabled = true

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_custom_domain" "global" {
  count                    = var.custom_fqdn != "" ? 1 : 0
  name                     = "CustomDomainFrontendEndpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  host_name   = var.custom_fqdn
  dns_zone_id = data.azurerm_dns_zone.customdomain[0].id

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "global" {
  count                          = var.custom_fqdn != "" ? 1 : 0
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.global[0].id
  cdn_frontdoor_route_ids = setunion(
    [azurerm_cdn_frontdoor_route.globalstorage.id],
    azurerm_cdn_frontdoor_route.staticstorage.*.id,
    azurerm_cdn_frontdoor_route.backendapi.*.id
  )
}

# Front Door Origin Group used for Backend APIs hosted on AKS
resource "azurerm_cdn_frontdoor_origin_group" "backendapis" {
  name = "BackendApis"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/healthservice/health/stamp"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 2
    additional_latency_in_milliseconds = 1000
  }
}

# Front Door Origin Group used for Global Storage Accounts
resource "azurerm_cdn_frontdoor_origin_group" "globalstorage" {
  name = "GlobalStorage"

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/health.check"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 2
    additional_latency_in_milliseconds = 1000
  }

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Front Door Origin Group used for Static Storage Accounts
resource "azurerm_cdn_frontdoor_origin_group" "staticstorage" {
  name = "StaticStorage"

  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/"
    interval_in_seconds = 30
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 2
    additional_latency_in_milliseconds = 1000
  }

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-primary" {
  name      = "primary"
  host_name = azurerm_storage_account.global.primary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 1

  enabled                        = true
  certificate_name_check_enabled = true

  origin_host_header = azurerm_storage_account.global.primary_web_host

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_origin" "globalstorage-secondary" {
  name      = "secondary"
  host_name = azurerm_storage_account.global.secondary_web_host

  http_port  = 80
  https_port = 443
  weight     = 1
  priority   = 2

  enabled                        = true
  certificate_name_check_enabled = true

  origin_host_header = azurerm_storage_account.global.secondary_web_host

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id
}

resource "azurerm_cdn_frontdoor_route" "globalstorage" {
  name                          = "GlobalStorageRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.globalstorage.id

  cdn_frontdoor_custom_domain_ids = var.custom_fqdn != "" ? [azurerm_cdn_frontdoor_custom_domain.global.0.id] : null

  patterns_to_match = [
    "/images/*"
  ]

  supported_protocols = [
    "Http", # HTTP needs to be enabled explicity, so that https_redirect_enabled = true (default) works
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.globalstorage-primary.id,
    azurerm_cdn_frontdoor_origin.globalstorage-secondary.id
  ]
}

resource "azurerm_cdn_frontdoor_origin" "backendapi" {
  for_each = { for index, backend in var.backends_BackendApis : backend.address => backend }

  name               = replace(each.value.address, ".", "-") # Name must not contain dots, so we use hyphens instead
  host_name          = each.value.address
  origin_host_header = each.value.address
  weight             = each.value.weight

  enabled                        = each.value.enabled
  certificate_name_check_enabled = true

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "backendapi" {
  count                         = length(var.backends_BackendApis) > 0 ? 1 : 0 # only create this route if there are already backends
  name                          = "BackendApiRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backendapis.id

  cdn_frontdoor_custom_domain_ids = var.custom_fqdn != "" ? [azurerm_cdn_frontdoor_custom_domain.global.0.id] : null

  patterns_to_match = [
    "/catalogservice/*",
    "/healthservice/*"
  ]

  supported_protocols = [
    "Http", # HTTP needs to be enabled explicity, so that https_redirect_enabled = true (default) works
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  cdn_frontdoor_origin_ids = [for i, b in azurerm_cdn_frontdoor_origin.backendapi : b.id]
}

resource "azurerm_cdn_frontdoor_origin" "staticstorage" {
  for_each = { for index, backend in var.backends_StaticStorage : backend.address => backend }

  name               = replace(each.value.address, ".", "-") # Name must not contain dots, so we use hyphens instead
  host_name          = each.value.address
  origin_host_header = each.value.address
  weight             = each.value.weight

  enabled                        = each.value.enabled
  certificate_name_check_enabled = true

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "staticstorage" {
  count                         = length(var.backends_StaticStorage) > 0 ? 1 : 0 # only create this route if there are already backends
  name                          = "StaticStorageRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default.id
  enabled                       = true
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staticstorage.id

  cdn_frontdoor_custom_domain_ids = var.custom_fqdn != "" ? [azurerm_cdn_frontdoor_custom_domain.global.0.id] : null

  patterns_to_match = [
    "/*"
  ]

  supported_protocols = [
    "Http", # HTTP needs to be enabled explicity, so that https_redirect_enabled = true (default) works
    "Https"
  ]
  forwarding_protocol = "HttpsOnly"

  cdn_frontdoor_origin_ids = [for i, b in azurerm_cdn_frontdoor_origin.staticstorage : b.id]
}

#### WAF

resource "azurerm_cdn_frontdoor_firewall_policy" "global" {
  name                = "${local.prefix}globalfdfp"
  resource_group_name = azurerm_resource_group.global.name
  sku_name            = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.0"
    action  = "Block"
  }
  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "global" {
  name                     = "Global-Security-Policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.global.id
      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.default.id
        }

        dynamic "domain" {
          for_each = azurerm_cdn_frontdoor_custom_domain.global
          content {
            cdn_frontdoor_domain_id = domain.value.id
          }
        }
      }
    }
  }
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "frontdoor" {
  resource_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name                       = "afdladiagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.global.id

  dynamic "enabled_log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.log_category_types

    content {
      category = entry.value

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}
