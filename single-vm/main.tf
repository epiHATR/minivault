terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.61.0"
    }
  }
}

locals {
  vnet            = "${var.vault_server_name}-vm01-vnet"
  subnet          = "${var.vault_server_name}-vm01-subnet"
  publicIp        = "${var.vault_server_name}-vm01-pip"
  nsg             = "${var.vault_server_name}-vm01-nsg"
  nic             = "${var.vault_server_name}-vm01-nic"
  vmName          = "${var.vault_server_name}-vm01"
  computer_name   = var.vault_server_name
  os_disk         = "${var.vault_server_name}-vm01-osDisk"
  storage_account = "${var.vault_server_name}${random_id.storage.hex}"
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}

resource "random_pet" "rg_name" {
  prefix = local.computer_name
  length = 1
}

resource "random_id" "storage" {
  byte_length = 2
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}


# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = local.vnet
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = local.subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = local.publicIp
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = azurerm_resource_group.rg.name
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = local.nsg
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHttpInbound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = local.nic
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = local.storage_account
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = local.vmName
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = local.os_disk
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = local.computer_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }

  custom_data = filebase64("${path.module}/scripts/cloud-init.txt")
}

resource "azurerm_storage_account" "vaultstorage" {
  name                     = "${var.vault_server_name}storagesa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "vaultstorage_container" {
  name                  = var.vault_server_name
  storage_account_name  = azurerm_storage_account.vaultstorage.name
  container_access_type = "private"
}

resource "time_sleep" "wait_2_minute" {
  create_duration = "2m"

  depends_on = [azurerm_linux_virtual_machine.my_terraform_vm]
}

resource "azurerm_virtual_machine_extension" "vault-demo" {
  name                 = "vault-demo-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.my_terraform_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings   = <<SETTINGS
    {
      "commandToExecute": "${var.cmd_extension} ${azurerm_storage_account.vaultstorage.name} ${azurerm_storage_container.vaultstorage_container.name} ${azurerm_storage_account.vaultstorage.primary_access_key}",
       "fileUris": [
        "${var.cmd_script}"
       ]
    }
SETTINGS
  depends_on = [time_sleep.wait_2_minute]
}
