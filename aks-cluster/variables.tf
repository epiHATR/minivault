variable "cluster_name" {
  type = string
}

variable "cluster_location" {
  type    = string
  default = "northeurope"
}

variable "aks_version" {
  type = string
  default = "1.26.3"
}

variable "vault_server_url" {
  type = string
}

variable "argocd_manifest_pat" {
  type = string
}