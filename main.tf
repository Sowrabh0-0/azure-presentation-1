module "resource_group" {
  source   = "./modules/resource-group"
  name     = "RG-1"
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_container_registry" "main" {
  name                = var.container_registry_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.default_tags
}

resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "${local.name_prefix}-ddos-plan"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.default_tags
}

module "hub_vnet" {
  source              = "./modules/network"
  name                = "RG-1-VNET-1-HUB"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["172.16.0.0/16"]
  subnets             = local.hub_subnets
  ddos_plan_id        = azurerm_network_ddos_protection_plan.main.id
  tags                = local.default_tags
}

module "opslora_vnet" {
  source              = "./modules/network"
  name                = "RG-1-VNET-2-Spoke"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.10.0.0/16"]
  subnets             = local.opslora_subnets
  ddos_plan_id        = azurerm_network_ddos_protection_plan.main.id
  tags                = local.default_tags
}

module "pronunt_vnet" {
  source              = "./modules/network"
  name                = "RG-1-VNET-3-Spoke"
  resource_group_name = module.resource_group.name
  location            = var.pronunt_location
  address_space       = ["10.20.0.0/16"]
  subnets             = local.pronunt_subnets
  ddos_plan_id        = azurerm_network_ddos_protection_plan.main.id
  tags                = local.default_tags
}

resource "azurerm_virtual_network_peering" "hub_to_opslora" {
  name                         = "hub-to-opslora"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.hub_vnet.name
  remote_virtual_network_id    = module.opslora_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_vpn_gateway
  depends_on                   = [module.vpn_gateway]
}

resource "azurerm_virtual_network_peering" "opslora_to_hub" {
  name                         = "opslora-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.opslora_vnet.name
  remote_virtual_network_id    = module.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.enable_vpn_gateway
  depends_on                   = [azurerm_virtual_network_peering.hub_to_opslora, module.vpn_gateway]
}

resource "azurerm_virtual_network_peering" "hub_to_pronunt" {
  name                         = "hub-to-pronunt"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.hub_vnet.name
  remote_virtual_network_id    = module.pronunt_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_vpn_gateway
  depends_on                   = [module.vpn_gateway]
}

resource "azurerm_virtual_network_peering" "pronunt_to_hub" {
  name                         = "pronunt-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.pronunt_vnet.name
  remote_virtual_network_id    = module.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.enable_vpn_gateway
  depends_on                   = [azurerm_virtual_network_peering.hub_to_pronunt, module.vpn_gateway]
}

module "app_nsg" {
  source              = "./modules/nsg"
  name                = "${local.name_prefix}-app-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  security_rules = [
    {
      name                       = "Allow-AppGateway-Http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "172.16.40.0/26"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Bastion-SSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "172.16.10.0/26"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-OnPrem-Private"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefixes    = var.onprem_address_space
      destination_address_prefix = "*"
    }
  ]
  tags = local.default_tags
}

module "pronunt_app_nsg" {
  source              = "./modules/nsg"
  name                = "${local.name_prefix}-pronunt-app-nsg"
  resource_group_name = module.resource_group.name
  location            = var.pronunt_location
  security_rules = [
    {
      name                       = "Allow-AppGateway-Http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "172.16.40.0/26"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Bastion-SSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "172.16.10.0/26"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-OnPrem-Private"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefixes    = var.onprem_address_space
      destination_address_prefix = "*"
    }
  ]
  tags = local.default_tags
}

module "app_gateway_nsg" {
  source              = "./modules/nsg"
  name                = "${local.name_prefix}-appgw-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  security_rules = [
    {
      name                       = "Allow-Internet-HTTP-HTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-GatewayManager"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-AzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
  ]
  tags = local.default_tags
}

resource "azurerm_subnet_network_security_group_association" "opslora_app" {
  subnet_id                 = module.opslora_vnet.subnet_ids["app"]
  network_security_group_id = module.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pronunt_app" {
  subnet_id                 = module.pronunt_vnet.subnet_ids["app"]
  network_security_group_id = module.pronunt_app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = module.hub_vnet.subnet_ids["ApplicationGatewaySubnet"]
  network_security_group_id = module.app_gateway_nsg.id
}

module "firewall" {
  source              = "./modules/firewall"
  name                = "${local.name_prefix}-azfw"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
  tags                = local.default_tags

  network_rule_collections = [
    {
      name     = "allow-spokes-to-platform"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "allow-spokes-dns"
          source_addresses      = ["10.10.0.0/16", "10.20.0.0/16"]
          destination_ports     = ["53"]
          destination_addresses = ["0.0.0.0/0"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "allow-spokes-web-egress"
          source_addresses      = ["10.10.0.0/16", "10.20.0.0/16"]
          destination_ports     = ["80", "443"]
          destination_addresses = ["0.0.0.0/0"]
          protocols             = ["TCP"]
        },
        {
          name                  = "allow-onprem-to-spokes"
          source_addresses      = var.onprem_address_space
          destination_ports     = ["80", "443", "22"]
          destination_addresses = ["10.10.0.0/16", "10.20.0.0/16"]
          protocols             = ["TCP"]
        }
      ]
    }
  ]
}

module "spoke_routes" {
  source              = "./modules/route-table"
  name                = "${local.name_prefix}-spoke-rt"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  routes = [
    {
      name                   = "default-through-azure-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    },
    {
      name                   = "onprem-through-azure-firewall"
      address_prefix         = "10.30.0.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  ]
  subnet_ids = {
    opslora = module.opslora_vnet.subnet_ids["app"]
  }
  tags = local.default_tags
}

module "pronunt_spoke_routes" {
  source              = "./modules/route-table"
  name                = "${local.name_prefix}-pronunt-spoke-rt"
  resource_group_name = module.resource_group.name
  location            = var.pronunt_location
  routes = [
    {
      name                   = "default-through-azure-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    },
    {
      name                   = "onprem-through-azure-firewall"
      address_prefix         = "10.30.0.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  ]
  subnet_ids = {
    pronunt = module.pronunt_vnet.subnet_ids["app"]
  }
  tags = local.default_tags
}

module "bastion" {
  count               = var.enable_bastion ? 1 : 0
  source              = "./modules/bastion"
  name                = "${local.name_prefix}-bastion"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]
  tags                = local.default_tags
}

module "app_gateway" {
  source              = "./modules/application-gateway"
  name                = "${local.name_prefix}-appgw"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.hub_vnet.subnet_ids["ApplicationGatewaySubnet"]
  backend_pools       = local.appgw_backend_pools
  tags                = local.default_tags
}

module "opslora_internal_lb" {
  source              = "./modules/internal-load-balancer"
  name                = "${local.name_prefix}-opslora-ilb"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.opslora_vnet.subnet_ids["app"]
  private_ip_address  = "10.10.10.10"
  tags                = local.default_tags
}

module "pronunt_internal_lb" {
  source              = "./modules/internal-load-balancer"
  name                = "${local.name_prefix}-pronunt-ilb"
  resource_group_name = module.resource_group.name
  location            = var.pronunt_location
  subnet_id           = module.pronunt_vnet.subnet_ids["app"]
  private_ip_address  = "10.20.10.10"
  tags                = local.default_tags
}

module "sql" {
  source              = "./modules/azure-sql"
  name                = "${local.name_prefix}-sql"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  admin_login         = var.sql_admin_login
  admin_password      = var.sql_admin_password
  databases           = var.sql_databases
  tags                = local.default_tags
}

module "cosmos_mongo" {
  source              = "./modules/cosmos-mongo"
  name                = "${local.name_prefix}-mongo"
  resource_group_name = module.resource_group.name
  location            = var.pronunt_location
  database_name       = "pronunt"
  tags                = local.default_tags
}

module "sql_private_endpoint" {
  source                         = "./modules/private-endpoint"
  name                           = "${local.name_prefix}-sql-pe"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.opslora_vnet.subnet_ids["private_endpoints"]
  private_connection_resource_id = module.sql.server_id
  subresource_names              = ["sqlServer"]
  private_dns_zone_name          = "privatelink.database.windows.net"
  virtual_network_ids = {
    hub     = module.hub_vnet.id
    opslora = module.opslora_vnet.id
  }
  tags = local.default_tags
}

module "cosmos_private_endpoint" {
  source                         = "./modules/private-endpoint"
  name                           = "${local.name_prefix}-mongo-pe"
  resource_group_name            = module.resource_group.name
  location                       = var.pronunt_location
  subnet_id                      = module.pronunt_vnet.subnet_ids["private_endpoints"]
  private_connection_resource_id = module.cosmos_mongo.id
  subresource_names              = ["MongoDB"]
  private_dns_zone_name          = "privatelink.mongo.cosmos.azure.com"
  virtual_network_ids = {
    hub     = module.hub_vnet.id
    pronunt = module.pronunt_vnet.id
  }
  tags = local.default_tags
}

module "opslora_vmss" {
  source                         = "./modules/linux-vmss"
  name                           = "${local.name_prefix}-opslora-vmss"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.opslora_vnet.subnet_ids["app"]
  admin_username                 = var.admin_username
  admin_password                 = var.admin_password
  sku                            = var.vmss_sku
  instances                      = var.vmss_min_capacity
  min_capacity                   = var.vmss_min_capacity
  max_capacity                   = var.vmss_max_capacity
  load_balancer_backend_pool_ids = [module.opslora_internal_lb.backend_pool_id]
  zones                          = ["2"]
  custom_data = templatefile("${path.module}/cloud-init/opslora.yaml.tftpl", {
    images                      = var.opslora_images
    sql_server_fqdn             = module.sql.fqdn
    sql_admin_login             = var.sql_admin_login
    sql_admin_pass              = var.sql_admin_password
    jwt_secret                  = var.opslora_jwt_secret
    container_registry_server   = var.container_registry_server != "" ? var.container_registry_server : azurerm_container_registry.main.login_server
    container_registry_username = var.container_registry_username != "" ? var.container_registry_username : azurerm_container_registry.main.admin_username
    container_registry_password = var.container_registry_password != "" ? var.container_registry_password : azurerm_container_registry.main.admin_password
  })
  tags = local.default_tags
}

module "pronunt_vmss" {
  source                         = "./modules/linux-vmss"
  name                           = "${local.name_prefix}-pronunt-vmss"
  resource_group_name            = module.resource_group.name
  location                       = var.pronunt_location
  subnet_id                      = module.pronunt_vnet.subnet_ids["app"]
  admin_username                 = var.admin_username
  admin_password                 = var.admin_password
  sku                            = var.pronunt_vmss_sku
  instances                      = var.vmss_min_capacity
  min_capacity                   = var.vmss_min_capacity
  max_capacity                   = var.vmss_max_capacity
  load_balancer_backend_pool_ids = [module.pronunt_internal_lb.backend_pool_id]
  zones                          = ["2"]
  custom_data = templatefile("${path.module}/cloud-init/pronunt.yaml.tftpl", {
    images                      = var.pronunt_images
    cosmos_mongo_uri            = module.cosmos_mongo.primary_mongodb_connection_string
    internal_service_token      = var.pronunt_internal_service_token
    session_jwt_secret          = var.pronunt_session_jwt_secret
    openai_api_key              = var.openai_api_key
    github_client_id            = var.github_oauth_client_id
    github_client_secret        = var.github_oauth_client_secret
    container_registry_server   = var.container_registry_server != "" ? var.container_registry_server : azurerm_container_registry.main.login_server
    container_registry_username = var.container_registry_username != "" ? var.container_registry_username : azurerm_container_registry.main.admin_username
    container_registry_password = var.container_registry_password != "" ? var.container_registry_password : azurerm_container_registry.main.admin_password
  })
  tags = local.default_tags
}

module "vpn_gateway" {
  count                   = var.enable_vpn_gateway ? 1 : 0
  source                  = "./modules/vpn-gateway"
  name                    = "${local.name_prefix}-vpngw"
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  gateway_subnet_id       = module.hub_vnet.subnet_ids["GatewaySubnet"]
  local_gateway_public_ip = var.onprem_gateway_public_ip
  local_address_space     = var.onprem_address_space
  shared_key              = var.vpn_shared_key
  tags                    = local.default_tags
}
