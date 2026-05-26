variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "gateway_subnet_id" {
  type = string
}

variable "local_gateway_public_ip" {
  type = string
}

variable "local_address_space" {
  type = list(string)
}

variable "shared_key" {
  type      = string
  sensitive = true
}

variable "gateway_sku" {
  type    = string
  default = "VpnGw1AZ"
}

variable "ipsec_policy" {
  description = "Custom IPsec/IKE proposal for the Azure VPN connection. Defaults match strongSwan aes256-sha2_256;modp2048 with PFS 2048."
  type = object({
    dh_group         = string
    ike_encryption   = string
    ike_integrity    = string
    ipsec_encryption = string
    ipsec_integrity  = string
    pfs_group        = string
    sa_datasize      = number
    sa_lifetime      = number
  })
  default = {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_datasize      = 102400000
    sa_lifetime      = 27000
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
