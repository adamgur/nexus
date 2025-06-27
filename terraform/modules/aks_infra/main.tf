terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
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

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
    Project     = "Nexus"
  }
}

module "ServicePrincipal" {
  source              = "../ServicePrincipal"
  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  environment         = var.environment

  depends_on = [
    azurerm_resource_group.aks
  ]
}

resource "azurerm_role_assignment" "rolespn" {

  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = module.ServicePrincipal.service_principal_object_id

  depends_on = [
    module.ServicePrincipal
  ]
}

module "aks_with_acr" {
  source             = "../aks_with_acr"
  cluster_name       = var.cluster_name
  location           = var.location
  acr_name           = var.acr_name
  node_count         = var.node_count == "" ? 2 : var.node_count 
  node_vm_size       = var.node_vm_size == "" ? "Standard_D2s_v3" : var.node_vm_size 
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : data.azurerm_kubernetes_service_versions.current.latest_version
  client_id          = module.ServicePrincipal.client_id
  client_secret      = module.ServicePrincipal.client_secret
  subscription_id    = var.subscription_id
  resource_group_name = var.resource_group_name
  environment        = var.environment
}

data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
}
