data "azurerm_kubernetes_cluster" "default" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
  depends_on          = [azurerm_kubernetes_cluster.aks]
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt("randomPassword")
  }

  depends_on = [ data.azurerm_kubernetes_cluster.default ]
}

resource "kubernetes_secret" "argocd_repository_secret" {
  metadata {
    name      = "vaulity-manifest"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" : "repository"
    }
  }

  data = {
    name : "vaulity-manifest"
    url : "https://github.com/epiHATR/minivault-manifests"
    password : var.argocd_manifest_pat
    username : "argocd"
    forceHttpBasicAuth : "true"
  }

  depends_on = [helm_release.argocd]
}

resource "helm_release" "argocd_gitops" {
  name       = "argocd-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = "argocd"

  values = [file("${path.module}/argocd-apps.yaml")]

  set {
    name  = "projects[0].name"
    value = "argocd-apps"
  }

  set {
    name  = "projects[0].description"
    value = "argocd-apps descriptions"
  }

  set {
    name  = "applications[0].name"
    value = "argocd-apps"
  }

  set {
    name  = "applications[0].project"
    value = "argocd-apps"
  }

  set {
    name  = "applications[0].source.repoURL"
    value = "https://github.com/epiHATR/minivault-manifests"
  }

  set {
    name  = "applications[0].source.path"
    value = "customers"
  }

  set {
    name  = "applications[0].source.targetRevision"
    value = "master"
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_repository_secret
  ]
}
