resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
    Project     = "Nexus"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = "false"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = var.resource_group_name
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
    Environment = var.environment
  }
}

data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
}

# resource "kubernetes_namespace" "production" {
#   metadata {
#     name = "production"
#   }
# }

# resource "kubernetes_namespace" "dev" {
#   metadata {
#     name = "dev"
#   }
# }

# resource "kubernetes_namespace" "staging" {
#   metadata {
#     name = "staging"
#   }
# }

# Commented out - using provider configuration from root module
# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
# }
