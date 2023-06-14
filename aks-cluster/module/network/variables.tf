variable "vnet_name" {
  type = string
}

variable "address_prefix" {
  type = string
}

variable "location" {
  type =  string
}

variable "resource_group_name" {
  type = string
}

variable "cluster_subnet_name" {
  type = string
}

variable "cluster_subnet_address_prefix" {
  type = string
}

variable "ingress_pip_name" {
  type = string
}

variable "ingress_pip_location" {
  type = string
}

variable "egress_pip_name" {
  type = string
}

variable "egress_pip_location" {
  type = string
}

variable "domain_name_label" {
  type = string
}