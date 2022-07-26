resource "azurerm_frontdoor" "main" {
  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.global.name

  tags = local.default_tags

  depends_on = [
    azurerm_dns_cname_record.app_subdomain
  ]

  routing_rule {
    name               = "API-rule"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/catalogservice/*", "/healthservice/*"]
    frontend_endpoints = [(var.custom_fqdn != "" ? local.frontdoor_custom_frontend_name : local.frontdoor_default_frontend_name)]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "BackendApis"
    }
  }

  routing_rule {
    name               = "UI-rule"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [(var.custom_fqdn != "" ? local.frontdoor_custom_frontend_name : local.frontdoor_default_frontend_name)]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "StaticStorage"

      # Since the UI app is a SPA (single page application), usually the entire app can be served from cache without the need to request it from the backend every time
      cache_enabled = true
    }
  }

  routing_rule {
    name               = "Images-rule"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/images/*"]
    frontend_endpoints = [(var.custom_fqdn != "" ? local.frontdoor_custom_frontend_name : local.frontdoor_default_frontend_name)]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "GlobalStorage"
      cache_enabled       = true # Cache the images
    }
  }

  # Routing rule to redirect all HTTP traffic to HTTPS endpoint
  routing_rule {
    name               = "HTTPS-Redirect"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [(var.custom_fqdn != "" ? local.frontdoor_custom_frontend_name : local.frontdoor_default_frontend_name)]
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      redirect_type     = "Moved"
    }
  }

  backend_pool_load_balancing {
    name                            = "LoadBalancingSettings"
    additional_latency_milliseconds = 1000 # This number should be in 10s of ms to make sure that stamps in the same regions are treated as equal. We are right now using a high value to ensure load levelling between regions as well.
  }

  backend_pool_health_probe {
    name                = "ApiHealthProbeSetting"
    protocol            = "Https"
    probe_method        = "HEAD"
    path                = "/healthservice/health/stamp"
    interval_in_seconds = 30
  }

  backend_pool_health_probe {
    name                = "StaticStorageHealthProbeSetting"
    protocol            = "Https"
    probe_method        = "HEAD"
    path                = "/"
    interval_in_seconds = 30
  }

  backend_pool_health_probe {
    name                = "GlobalStorageHealthProbeSetting"
    protocol            = "Https"
    probe_method        = "HEAD"
    path                = "/health.check"
    interval_in_seconds = 30
  }

  backend_pool_settings {
    enforce_backend_pools_certificate_name_check = true
    backend_pools_send_receive_timeout_seconds   = 60
  }

  backend_pool {
    name = "BackendApis"

    dynamic "backend" {
      for_each = var.backends_BackendApis
      content {
        host_header = backend.value.address
        address     = backend.value.address
        http_port   = 80
        https_port  = 443
        enabled     = backend.value.enabled
        weight      = backend.value.weight
      }
    }

    load_balancing_name = "LoadBalancingSettings"
    health_probe_name   = "ApiHealthProbeSetting"
  }

  backend_pool {
    name = "StaticStorage"

    dynamic "backend" {
      for_each = var.backends_StaticStorage
      content {
        host_header = backend.value.address
        address     = backend.value.address
        http_port   = 80
        https_port  = 443
        enabled     = backend.value.enabled
        weight      = backend.value.weight
      }
    }


    load_balancing_name = "LoadBalancingSettings"
    health_probe_name   = "StaticStorageHealthProbeSetting"
  }

  backend_pool {
    name = "GlobalStorage"

    backend {
      host_header = azurerm_storage_account.global.primary_web_host
      address     = azurerm_storage_account.global.primary_web_host
      http_port   = 80
      https_port  = 443
      enabled     = true
      weight      = 1
      priority    = 1
    }

    backend {
      host_header = azurerm_storage_account.global.secondary_web_host
      address     = azurerm_storage_account.global.secondary_web_host
      http_port   = 80
      https_port  = 443
      enabled     = true
      weight      = 1
      priority    = 2 # Use secondary location only in case the primary is not accessible in order to avoid issues due to replication latency of the GRS
    }

    load_balancing_name = "LoadBalancingSettings"
    health_probe_name   = "GlobalStorageHealthProbeSetting"
  }

  frontend_endpoint {
    name                     = local.frontdoor_default_frontend_name
    host_name                = local.frontdoor_default_dns_name
    session_affinity_enabled = false

    web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.main.id
  }

  dynamic "frontend_endpoint" {
    for_each = azurerm_dns_cname_record.app_subdomain # there is either 1 or 0 resources, depending on whether a custom domain name was supplied
    content {
      name                                    = local.frontdoor_custom_frontend_name
      host_name                               = trimsuffix(frontend_endpoint.value.fqdn, ".") # remove trailing dot (.) from the end of the FQDN
      session_affinity_enabled                = false
      web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.main.id
    }
  }
}

resource "azurerm_frontdoor_custom_https_configuration" "custom_domain_https" {
  count                             = var.custom_fqdn != "" ? 1 : 0
  frontend_endpoint_id              = "${azurerm_frontdoor.main.id}/frontendEndpoints/${local.frontdoor_custom_frontend_name}"
  custom_https_provisioning_enabled = true

  custom_https_configuration {
    certificate_source = "FrontDoor"
  }
}

resource "azurerm_frontdoor_firewall_policy" "main" {
  name                = "${lower(var.prefix)}globalfdfp"
  resource_group_name = azurerm_resource_group.global.name
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "1.1"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }

  tags = local.default_tags
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "frontdoor" {
  resource_id = azurerm_frontdoor.main.id
}

resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name                       = "frontdoorladiagnostics"
  target_resource_id         = azurerm_frontdoor.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.global.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.logs

    content {
      category = entry.value
      enabled  = true

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
