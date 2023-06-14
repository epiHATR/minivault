resource "helm_release" "vault_injector" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  set {
    name  = "injector.enabled"
    value = "true"
  }

  set {
    name  = "injector.externalVaultAddr"
    value = var.vault_server_url
  }

  set {
    name  = "injector.authPath"
    value = "auth/kubernetes/${var.cluster_name}-aks"
  }
}
