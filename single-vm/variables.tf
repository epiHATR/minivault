variable "vault_server_name" {
  type =  string
}

variable "resource_group_location" {
  type        = string
  default     = "northeurope"
  description = "Location of the resource group."
}

variable "cmd_extension" {
  type = string
  description = "Command to be excuted by the custom script extension"
  default     = "sh vault-install.sh"
}

variable "cmd_script" {
  type = string
  description = "Script to download which can be executed by the custom script extension"
  default     = "https://raw.githubusercontent.com/epiHATR/minivault/main/single-vm/scripts/vault-install.sh"
}