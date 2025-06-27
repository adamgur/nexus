variable "cluster_name" {
  type    = string
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

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "The Azure location for the resources"
  type        = string
  default     = "westeurope"
}

variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "environment" {
  description = "The Azure environment for the resources"
  type        = string
}