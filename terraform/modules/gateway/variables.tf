variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
}

variable "environment" {
  description = "The Azure environment for the resources"
  type        = string
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