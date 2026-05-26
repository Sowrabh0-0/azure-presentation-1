variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    name                              = optional(string)
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string))
    private_endpoint_network_policies = optional(string)
  }))
}

variable "ddos_plan_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
