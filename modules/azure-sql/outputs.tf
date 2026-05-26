output "server_id" {
  value = azurerm_mssql_server.this.id
}

output "fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_ids" {
  value = { for key, db in azurerm_mssql_database.this : key => db.id }
}
