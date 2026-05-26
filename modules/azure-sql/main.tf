resource "azurerm_mssql_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.admin_login
  administrator_login_password  = var.admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_mssql_database" "this" {
  for_each = toset(var.databases)

  name           = each.value
  server_id      = azurerm_mssql_server.this.id
  sku_name       = var.database_sku_name
  max_size_gb    = var.database_max_size_gb
  zone_redundant = false
  tags           = var.tags
}
