variable cluster_name {
    type = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "environment" {
  description = "The Azure environment for the resources"
  type        = string
}