resource "azurerm_resource_group" "aks" {
  name     = "${var.cluster_name}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = "false"

  tags = {
    Environment = "Dev"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = var.node_count 
    vm_size    = var.node_vm_size
  }

  service_principal  {
    client_id = var.client_id
    client_secret = var.client_secret
  }

   kubernetes_version = var.kubernetes_version

  tags = {
    Environment = "Dev"
  }
}

data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
}

resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}
