terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }

}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

module "aks" {
    source = "./modules/aks_infra"
    cluster_name       = var.cluster_name
    kubernetes_version = var.kubernetes_version
    node_count         = var.node_count
    node_vm_size       = var.node_vm_size
    subscription_id    = var.subscription_id
    resource_group_name = var.resource_group_name
    environment        = var.environment
    acr_name           = var.acr_name
    providers = {
      kubernetes = kubernetes
      helm       = helm
    }
}

module "gateway" {
  source              = "./modules/gateway"
  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  providers = {
    kubernetes = kubernetes
    helm       = helm
    azurerm    = azurerm
  }
  depends_on = [module.aks]
}