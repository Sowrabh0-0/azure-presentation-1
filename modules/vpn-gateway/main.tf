resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  bgp_enabled         = false
  sku                 = var.gateway_sku
  tags                = var.tags

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }
}

resource "azurerm_local_network_gateway" "this" {
  name                = "${var.name}-onprem-lgw"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.local_gateway_public_ip
  address_space       = var.local_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  name                       = "${var.name}-to-onprem"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this.id
  shared_key                 = var.shared_key
  tags                       = var.tags

  ipsec_policy {
    dh_group         = var.ipsec_policy.dh_group
    ike_encryption   = var.ipsec_policy.ike_encryption
    ike_integrity    = var.ipsec_policy.ike_integrity
    ipsec_encryption = var.ipsec_policy.ipsec_encryption
    ipsec_integrity  = var.ipsec_policy.ipsec_integrity
    pfs_group        = var.ipsec_policy.pfs_group
    sa_datasize      = var.ipsec_policy.sa_datasize
    sa_lifetime      = var.ipsec_policy.sa_lifetime
  }
}
