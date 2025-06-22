# terraform/variables.tf

variable "resource_group_name_prefix" {
  description = "A prefix for the resource group name for each cluster (e.g., 'my-aks-rg'). The cluster name will be appended."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
}
variable "subscription_id" {
  description = "Azure Subscription ID where the resources will be created."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = string
}

variable "node_vm_size" {
  description = "Size of the virtual machines in the node pool"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use for the cluster"
  type        = string
}
variable "clusters" {
  description = "A map defining configurations for each AKS cluster and its associated Application Gateway."
  type = map(object({
    cluster_name          = string
    environment           = string 
    vnet_address_space    = string
    aks_subnet_cidr       = string
    appgw_subnet_cidr     = string
    # Add other cluster-specific variables here if needed, e.g., node_count, vm_size
  }))
  default = {
    "nexus-dev-cluster" = {
      cluster_name          = "nexus-dev-cluster-01"
      environment           = "dev"
      vnet_address_space    = "10.0.0.0/16"
      aks_subnet_cidr       = "10.0.0.0/24"
      appgw_subnet_cidr     = "10.0.1.0/24"
    },
    "nexus-staging-cluster" = {
      cluster_name          = "nexus-staging-cluster-01"
      environment           = "staging"
      vnet_address_space    = "10.1.0.0/16"
      aks_subnet_cidr       = "10.1.0.0/24"
      appgw_subnet_cidr     = "10.1.1.0/24"
    },
    "nexus-prod-cluster" = {
      cluster_name          = "nexus-prod-cluster-01"
      environment           = "production"
      vnet_address_space    = "10.2.0.0/16"
      aks_subnet_cidr       = "10.2.0.0/24"
      appgw_subnet_cidr     = "10.2.1.0/24"
    }
    # Add more clusters here as needed
  }
}