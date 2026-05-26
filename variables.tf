variable "project" {
  description = "Project name used for resource naming."
  type        = string
  default     = "opslora"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "presentation"
}

variable "location" {
  description = "Primary Azure region for hub, Opslora spoke, and shared services."
  type        = string
  default     = "Central India"
}

variable "pronunt_location" {
  description = "Azure region for the Pronunt spoke."
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "admin_username" {
  description = "Linux admin username for VMSS instances."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Linux admin password for VMSS instances. Must satisfy Azure VM password complexity rules."
  type        = string
  sensitive   = true
}

variable "vmss_sku" {
  description = "Default VM SKU for application VM scale sets."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "pronunt_vmss_sku" {
  description = "VM SKU for the Pronunt East US VMSS."
  type        = string
  default     = "Standard_L2aos_v4"
}

variable "container_registry_name" {
  description = "Azure Container Registry name used for Opslora and Pronunt images."
  type        = string
  default     = "opslorapres944337"
}

variable "container_registry_server" {
  description = "Optional override for the container registry login server used by cloud-init docker login. Leave empty to use the Terraform-managed ACR."
  type        = string
  default     = ""
}

variable "container_registry_username" {
  description = "Optional override for the container registry username used by cloud-init docker login. Leave empty to use the Terraform-managed ACR admin username."
  type        = string
  sensitive   = true
  default     = ""
}

variable "container_registry_password" {
  description = "Optional override for the container registry password used by cloud-init docker login. Leave empty to use the Terraform-managed ACR admin password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vmss_min_capacity" {
  description = "Minimum VMSS capacity."
  type        = number
  default     = 1
}

variable "vmss_max_capacity" {
  description = "Maximum VMSS capacity."
  type        = number
  default     = 3
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks allowed to reach management endpoints through NSGs."
  type        = list(string)
  default     = ["10.30.0.0/24"]
}

variable "enable_bastion" {
  description = "Create Azure Bastion in the hub."
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Create VPN gateway, local network gateway, and connection for on-prem. Enable when the on-prem lab gateway is ready."
  type        = bool
  default     = false
}

variable "onprem_address_space" {
  description = "On-prem address space."
  type        = list(string)
  default     = ["10.30.0.0/24"]
}

variable "onprem_gateway_public_ip" {
  description = "Public IP of the on-prem VPN gateway. Required when enable_vpn_gateway is true."
  type        = string
  default     = ""
}

variable "vpn_shared_key" {
  description = "IPsec pre-shared key for the site-to-site VPN connection."
  type        = string
  sensitive   = true
  default     = ""
}

variable "sql_admin_login" {
  description = "Azure SQL administrator login."
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Azure SQL administrator password."
  type        = string
  sensitive   = true
}

variable "sql_databases" {
  description = "Opslora Azure SQL databases."
  type        = list(string)
  default = [
    "opslora_auth",
    "opslora_customer",
    "opslora_inventory",
    "opslora_order",
    "opslora_invoice",
    "opslora_payment"
  ]
}

variable "opslora_images" {
  description = "Container images for Opslora services."
  type        = map(string)
  default = {
    auth         = "ghcr.io/replace-me/opslora-auth-service:latest"
    customer     = "ghcr.io/replace-me/opslora-customer-service:latest"
    inventory    = "ghcr.io/replace-me/opslora-inventory-service:latest"
    order        = "ghcr.io/replace-me/opslora-order-service:latest"
    invoice      = "ghcr.io/replace-me/opslora-invoice-service:latest"
    payment      = "ghcr.io/replace-me/opslora-payment-service:latest"
    notification = "ghcr.io/replace-me/opslora-notification-service:latest"
    frontend     = "ghcr.io/replace-me/opslora-frontend-service:latest"
  }
}

variable "pronunt_images" {
  description = "Container images for Pronunt services."
  type        = map(string)
  default = {
    frontend   = "ghcr.io/replace-me/pronunt-frontend-service:latest"
    config     = "ghcr.io/replace-me/pronunt-config-service:latest"
    aggregator = "ghcr.io/replace-me/pronunt-aggregator-service:latest"
    worker     = "ghcr.io/replace-me/pronunt-worker-service:latest"
    ingestion  = "ghcr.io/replace-me/pronunt-ingestion-service:latest"
    ai         = "ghcr.io/replace-me/pronunt-ai-service:latest"
    auth       = "ghcr.io/replace-me/pronunt-auth-service:latest"
  }
}

variable "opslora_jwt_secret" {
  description = "Opslora JWT secret injected into app containers."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

variable "pronunt_internal_service_token" {
  description = "Pronunt internal service token injected into app containers."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

variable "pronunt_session_jwt_secret" {
  description = "Pronunt session JWT secret."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

variable "openai_api_key" {
  description = "OpenAI API key for Pronunt AI service."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

variable "github_oauth_client_id" {
  description = "Pronunt GitHub OAuth client id."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

variable "github_oauth_client_secret" {
  description = "Pronunt GitHub OAuth client secret."
  type        = string
  sensitive   = true
  default     = "replace-me"
}
