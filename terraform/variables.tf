variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure location for the resources"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "node_vm_size" {
  description = "Size of the virtual machines in the node pool"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use for the cluster"
  type        = string
}

variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
}

variable "environment" {
  description = "The Azure environment for the resources"
  type        = string
}

variable "cert_manager_enabled" {
  description = "Enable cert-manager deployment"
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "The address space of the virtual network."
  type        = string
}

variable "aks_subnet_cidr" {
  description = "The address prefix for the AKS subnet."
  type        = string
}

variable "appgw_subnet_cidr" {
  description = "The address prefix for the Application Gateway subnet."
  type        = string
}
