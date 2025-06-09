terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }

}

provider "azurerm" {
  subscription_id = "d8815ffd-5993-4ba6-8389-ae8d958e1dff"
  features {}
}

module "aks" {
    source = "./modules/aks_infra"
    cluster_name       = var.cluster_name
    kubernetes_version = var.kubernetes_version
    node_count         = var.node_count
    node_vm_size       = var.node_vm_size
}