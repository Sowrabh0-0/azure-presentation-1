variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_throughput" {
  type    = number
  default = 400
}

variable "tags" {
  type    = map(string)
  default = {}
}
