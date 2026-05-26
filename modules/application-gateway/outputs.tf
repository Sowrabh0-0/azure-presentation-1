output "id" {
  value = azurerm_application_gateway.this.id
}

output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "backend_pool_ids" {
  value = {
    for key, name in local.backend_pool_names :
    key => one([
      for pool in azurerm_application_gateway.this.backend_address_pool :
      pool.id if pool.name == name
    ])
  }
}
