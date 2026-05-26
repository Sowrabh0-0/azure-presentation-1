output "resource_group_name" {
  value = module.resource_group.name
}

output "application_gateway_public_ip" {
  value = module.app_gateway.public_ip_address
}

output "application_gateway_dns_hint" {
  value = "Create A records for opslora.com and pronunt.com pointing to ${module.app_gateway.public_ip_address}."
}

output "vpn_gateway_public_ip" {
  value = var.enable_vpn_gateway ? module.vpn_gateway[0].public_ip_address : null
}

output "container_registry_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "opslora_vmss_name" {
  value = module.opslora_vmss.name
}

output "pronunt_vmss_name" {
  value = module.pronunt_vmss.name
}

output "sql_server_fqdn" {
  value = module.sql.fqdn
}

output "cosmos_mongo_endpoint" {
  value     = module.cosmos_mongo.endpoint
  sensitive = true
}
