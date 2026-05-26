locals {
  backend_pool_names = { for key, pool in var.backend_pools : key => "${key}-pool" }
  backend_http_names = { for key, pool in var.backend_pools : key => "${key}-http" }
  listener_names     = { for key, pool in var.backend_pools : key => "${key}-listener" }
  probe_names        = { for key, pool in var.backend_pools : key => "${key}-probe" }
  routing_rule_names = { for key, pool in var.backend_pools : key => "${key}-rule" }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name         = local.backend_pool_names[backend_address_pool.key]
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "probe" {
    for_each = var.backend_pools
    content {
      name                                      = local.probe_names[probe.key]
      protocol                                  = "Http"
      path                                      = probe.value.probe
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = false
      host                                      = probe.value.host_name
      match {
        status_code = ["200-399"]
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_pools
    content {
      name                  = local.backend_http_names[backend_http_settings.key]
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
      probe_name            = local.probe_names[backend_http_settings.key]
    }
  }

  dynamic "http_listener" {
    for_each = var.backend_pools
    content {
      name                           = local.listener_names[http_listener.key]
      frontend_ip_configuration_name = "public-frontend"
      frontend_port_name             = "http"
      protocol                       = "Http"
      host_name                      = http_listener.value.host_name
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.backend_pools
    content {
      name                       = local.routing_rule_names[request_routing_rule.key]
      rule_type                  = "Basic"
      http_listener_name         = local.listener_names[request_routing_rule.key]
      backend_address_pool_name  = local.backend_pool_names[request_routing_rule.key]
      backend_http_settings_name = local.backend_http_names[request_routing_rule.key]
      priority                   = 100 + index(keys(var.backend_pools), request_routing_rule.key)
    }
  }
}
