# Azure Hub-Spoke Terraform Automation
x
This Terraform stack builds the presentation architecture for two applications in Azure:

- Hub VNet: `RG-1-VNET-1-HUB`, `172.16.0.0/16`, Central India
- Opslora spoke: `RG-1-VNET-2-Spoke`, `10.10.0.0/16`, Central India
- Pronunt spoke: `RG-1-VNET-3-Spoke`, `10.20.0.0/16`, East US
- On-prem network placeholder: `10.30.0.0/24`
- Host-based routing:
  - `opslora.com` -> Opslora VMSS backend pool
  - `pronunt.com` -> Pronunt VMSS backend pool

## What It Creates

- Resource group `RG-1`
- Azure Container Registry for Opslora and Pronunt images
- DDoS protection plan attached to the hub and spoke VNets
- Hub/spoke VNets, subnets, and VNet peering
- Azure Bastion in `AzureBastionSubnet`
- Azure Firewall Standard in `AzureFirewallSubnet`
- Classic Azure Firewall network rule collections
- Route tables that send spoke default/on-prem traffic through Azure Firewall
- Application Gateway WAF_v2 with WAF policy and host-based listeners
- Linux VM scale sets for Opslora and Pronunt, min `1`, max `3`
- Autoscale rules based on CPU
- Azure SQL Server and Opslora databases
- Cosmos DB API for MongoDB for Pronunt
- Private endpoints and private DNS for SQL and Cosmos Mongo
- Optional VPN gateway, local network gateway, and IPsec connection
- Cloud-init based Docker Compose deployment for both apps

## Folder Layout

```text
.
|-- main.tf
|-- variables.tf
|-- locals.tf
|-- outputs.tf
|-- versions.tf
|-- cloud-init/
|-- examples/
`-- modules/
```

## Prerequisites

- Azure CLI authenticated with `az login`
- Terraform available in your terminal PATH
- Container images pushed to the configured Azure Container Registry
- DNS A records for `opslora.com` and `pronunt.com` pointing to the Application Gateway public IP

The cloud-init templates use image-based Docker Compose files. The Azure VMs cannot build from local folders on your laptop, so publish the app images first and set them in `terraform.tfvars`.

## Configure

Copy the example variables:

```powershell
Copy-Item .\examples\terraform.tfvars.example .\terraform.tfvars
```

Edit:

- `admin_password`
- `sql_admin_password`
- `container_registry_name`
- `opslora_images`
- `pronunt_images`
- app secrets such as `opslora_jwt_secret`, `openai_api_key`, and GitHub OAuth values

## Container Images

The current ACR is:

```text
opslorapres944337.azurecr.io
```

The image repositories have been pushed for both applications. To retry only the images that previously failed during remote build:

```powershell
.\scripts\build-failed-acr-images.ps1
```

Terraform manages the ACR and uses its admin credentials for VMSS `docker login` during cloud-init. For a production setup, prefer VMSS managed identity with `AcrPull`.

## Deploy

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

`RG-1` and `opslorapres944337` were created before the final Terraform import and are already imported into local state. If this state is recreated on another machine, import them before apply:

```powershell
terraform import module.resource_group.azurerm_resource_group.this /subscriptions/94433754-e73d-429d-85c9-f4cf47043e04/resourceGroups/RG-1
terraform import azurerm_container_registry.main /subscriptions/94433754-e73d-429d-85c9-f4cf47043e04/resourceGroups/RG-1/providers/Microsoft.ContainerRegistry/registries/opslorapres944337
```

After apply, create DNS A records for both hostnames using:

```powershell
terraform output application_gateway_public_ip
```

## VPN And On-Prem

VPN resources are intentionally disabled by default:

```hcl
enable_vpn_gateway = false
```

When the Ubuntu on-prem gateway VM is ready with a bridged adapter and host-only network, set:

```hcl
enable_vpn_gateway       = true
onprem_gateway_public_ip = "YOUR_ONPREM_PUBLIC_IP"
vpn_shared_key           = "YOUR_STRONG_PSK"
```

The Azure local network gateway is already modeled for `10.30.0.0/24`.

## Notes

- The diagram only showed app subnets in the spokes. This stack adds dedicated private endpoint subnets:
  - Opslora: `10.10.20.0/24`
  - Pronunt: `10.20.20.0/24`
- The firewall module uses classic `azurerm_firewall_network_rule_collection` resources, as requested.
- HTTPS listeners and certificates can be added once the domains and certificate source are decided.
- Central India VMSS SKU access is still the main apply-time risk. `terraform.tfvars` currently uses `Standard_B2s` for Opslora, but that SKU was previously observed as restricted for this subscription in Central India.
- Opslora currently appears to use MySQL/PyMySQL in the local Compose stack. This Terraform stack provisions Azure SQL because that was requested, and the cloud-init template emits `mssql+pyodbc` URLs. The Opslora service images must include the SQL Server SQLAlchemy driver dependencies before that runtime path will work.
