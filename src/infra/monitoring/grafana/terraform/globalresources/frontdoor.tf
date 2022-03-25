resource "azurerm_frontdoor" "afdgrafana" {

  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.rg.name

  routing_rule {
    name               = "routingrule-grafana"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [(var.custom_fqdn != "" ? local.frontdoor_custom_frontend_name : local.frontdoor_default_frontend_name)]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "BackendGrafana"
      cache_enabled       = false
    }
  }

  backend_pool_load_balancing {
    name = "backendLb"
  }

  backend_pool_health_probe {
    name     = "backendHealthGrafana"
    enabled  = true
    path     = "/api/health"
    protocol = "Https"
  }

  backend_pool {

    name = "BackendGrafana"

    dynamic "backend" {
      for_each = var.stamps
      content {
        host_header = "${local.prefix}-${substr(backend.value, 0, 5)}-app.azurewebsites.net"
        address     = "${local.prefix}-${substr(backend.value, 0, 5)}-app.azurewebsites.net"
        http_port   = 80
        https_port  = 443
        enabled     = true
        weight      = 1
      }
    }

    load_balancing_name = "backendLb"
    health_probe_name   = "backendHealthGrafana"

  }

  backend_pool_settings {
    enforce_backend_pools_certificate_name_check = true
    backend_pools_send_receive_timeout_seconds   = 60
  }

  frontend_endpoint {
    name      = local.frontdoor_default_frontend_name
    host_name = local.frontdoor_default_dns_name
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

  tags = local.default_tags
}