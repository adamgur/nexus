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

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}