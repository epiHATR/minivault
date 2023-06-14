# CREATE VNET
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = [var.address_prefix]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# CREATE SUBNET FOR CLUSTER
resource "azurerm_subnet" "cluster_subnet" {
  name                 = var.cluster_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.cluster_subnet_address_prefix]

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# CREATE PUBLIC IP ADDRESSES
resource "azurerm_public_ip" "ingress_pip" {
  name                = var.ingress_pip_name
  resource_group_name = var.resource_group_name
  location            = var.ingress_pip_location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  domain_name_label   = var.domain_name_label
}

resource "azurerm_public_ip" "egress_pip" {
  name                = var.egress_pip_name
  resource_group_name = var.resource_group_name
  location            = var.egress_pip_location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}