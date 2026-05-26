variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "databases" {
  type = list(string)
}

variable "database_sku_name" {
  type    = string
  default = "S0"
}

variable "database_max_size_gb" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}
