locals {
  name_prefix = lower("${var.project}-${var.environment}")

  default_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags
  )

  hub_subnets = {
    AzureBastionSubnet = {
      address_prefixes = ["172.16.10.0/26"]
    }
    GatewaySubnet = {
      address_prefixes = ["172.16.20.0/24"]
    }
    AzureFirewallSubnet = {
      address_prefixes = ["172.16.30.0/26"]
    }
    ApplicationGatewaySubnet = {
      address_prefixes = ["172.16.40.0/26"]
    }
  }

  opslora_subnets = {
    app = {
      name             = "RG-1-VNET-2-SUB-1-APP"
      address_prefixes = ["10.10.10.0/24"]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage"
      ]
    }
    private_endpoints = {
      name                              = "RG-1-VNET-2-SUB-2-PRIVATE-ENDPOINTS"
      address_prefixes                  = ["10.10.20.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }

  pronunt_subnets = {
    app = {
      name             = "RG-1-VNET-3-SUB-1-APP"
      address_prefixes = ["10.20.10.0/24"]
      service_endpoints = [
        "Microsoft.AzureCosmosDB",
        "Microsoft.Storage"
      ]
    }
    private_endpoints = {
      name                              = "RG-1-VNET-3-SUB-2-PRIVATE-ENDPOINTS"
      address_prefixes                  = ["10.20.20.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }

  appgw_backend_pools = {
    opslora = {
      host_name    = "opslora.com"
      probe        = "/health"
      ip_addresses = ["10.10.10.10"]
    }
    pronunt = {
      host_name    = "pronunt.com"
      probe        = "/health"
      ip_addresses = ["10.20.10.10"]
    }
  }
}
