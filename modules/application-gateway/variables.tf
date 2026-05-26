variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_pools" {
  type = map(object({
    host_name    = string
    probe        = string
    ip_addresses = optional(list(string), [])
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
