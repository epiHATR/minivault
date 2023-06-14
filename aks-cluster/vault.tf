provider "vault" {
  # Configuration options
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes/${var.cluster_name}-aks"
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = azurerm_kubernetes_cluster.aks.kube_config.0.host
  kubernetes_ca_cert     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  issuer                 = "api"
  disable_iss_validation = "true"

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "vault_mount" "kvv2" {
  path        = "customers"
  type        = "kv"
  options     = { version = "2" }
  description = "All customers configuration KV version 2."
}