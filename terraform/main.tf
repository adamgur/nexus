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



provider "kubectl" {
  host                   = module.aks.kube_config["host"]
  client_certificate     = base64decode(module.aks.kube_config["client_certificate"])
  client_key             = base64decode(module.aks.kube_config["client_key"])
  cluster_ca_certificate = base64decode(module.aks.kube_config["cluster_ca_certificate"])
  load_config_file       = false
}