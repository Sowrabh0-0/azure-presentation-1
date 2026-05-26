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

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku" {
  type = string
}

variable "instances" {
  type = number
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "application_gateway_backend_pool_ids" {
  type    = list(string)
  default = []
}

variable "load_balancer_backend_pool_ids" {
  type    = list(string)
  default = []
}

variable "zones" {
  type    = list(string)
  default = null
}

variable "custom_data" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
