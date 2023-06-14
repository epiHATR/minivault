terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.49.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "3.16.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}

locals {
  aks_name                      = "${var.cluster_name}-aks"
  aks_node_rg                   = "${var.cluster_name}-aks"
  vnet_name                     = "${var.cluster_name}-vnet"
  vnet_address_prefix           = "10.80.0.0/16"
  cluster_subnet_address_prefix = "10.80.0.0/24"
  ingress_pip_name              = "${var.cluster_name}-aks-ingress"
  domain_name_label             = "${var.cluster_name}-aks-dns"
  egress_pip_name               = "${var.cluster_name}-aks-egress"

}

# CREATE RESOURCE GROUP FOR CLUSTER
resource "azurerm_resource_group" "cluster_rg" {
  name     = var.cluster_name
  location = var.cluster_location
}

# CREATE AKS NETWORKING RESOURCES
module "network" {
  source = "./module/network"

  vnet_name                     = local.vnet_name
  address_prefix                = local.vnet_address_prefix
  location                      = var.cluster_location
  resource_group_name           = var.cluster_name
  cluster_subnet_name           = local.aks_name
  cluster_subnet_address_prefix = local.cluster_subnet_address_prefix
  ingress_pip_name              = local.ingress_pip_name
  ingress_pip_location          = var.cluster_location
  egress_pip_name               = local.egress_pip_name
  egress_pip_location           = var.cluster_location
  domain_name_label             = local.domain_name_label

  depends_on = [azurerm_resource_group.cluster_rg]
}

# CREATE AZURE KUBERNETES SERVICES
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.cluster_rg.location
  resource_group_name = azurerm_resource_group.cluster_rg.name
  dns_prefix          = local.aks_name
  kubernetes_version  = var.aks_version
  node_resource_group = local.aks_node_rg

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    load_balancer_profile {
      outbound_ip_address_ids = [module.network.egress_pip_id]
    }
  }

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_B2s"
    os_sku         = "Ubuntu"
    vnet_subnet_id = module.network.cluster_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [module.network]
}

