variable "cluster_name" {
  type    = string
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

variable "rgname" {
  type        = string
  description = "resource group name"
  default = "nexus-rg"
}

variable "subscription_id" {
  type    = string
  default = "d8815ffd-5993-4ba6-8389-ae8d958e1dff"
}

variable "location" {
  description = "The Azure location for the resources"
  type        = string
  default     = "westeurope"
}

variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
  default     = "nexustestacr1"
}