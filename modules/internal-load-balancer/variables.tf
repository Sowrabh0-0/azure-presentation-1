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

variable "private_ip_address" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
