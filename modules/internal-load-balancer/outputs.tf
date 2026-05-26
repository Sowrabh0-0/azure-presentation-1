output "frontend_private_ip_address" {
  value = var.private_ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.this.id
}
